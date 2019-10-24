terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
}

provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

data "aws_availability_zones" "available" {
}

locals {
  cluster_name = "knative-lab-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "aws_security_group" "worker_group_mgmt" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.17.0"

  name                 = "knative-lab-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

data "template_file" "cluster_autoscaler_values" {
  template = file("${path.module}/templates/cluster_autoscaler_values.tpl")

  vars = {
    region = var.region
    cluster_name = local.cluster_name
  }
}

resource "local_file" "cluster_autoscaler_values" {
  content  = data.template_file.cluster_autoscaler_values.rendered
  filename = "./k8s/cluster-autoscaler-values.yaml"
}

data "template_file" "post_deploy_instructions" {
  template = file("${path.module}/templates/postdeploy.tpl")

  vars = {
    cluster_name = local.cluster_name
  }
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  version      = "6.0.2"
  cluster_name = local.cluster_name
  subnets      = module.vpc.private_subnets
  vpc_id       = module.vpc.vpc_id

  cluster_enabled_log_types     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_log_retention_in_days = 3

  tags = {
    Environment = "lab"
    GithubRepo  = "aws-knative-lab"
    GithubOrg   = "ck99"
  }

  attach_worker_autoscaling_policy  = true

  worker_groups = [
    {
      name                          = "on-demand-1a"
      instance_type                 = "t3.small"
      asg_min_size                  = 0
      asg_max_size                  = 1
      autoscaling_enabled           = true
      kubelet_extra_args            = "--register-with-taints=node-role.kubernetes.io/worker=true:PreferNoSchedule --node-labels=node-role.kubernetes.io/worker=true --node-labels=spot=false --node-labels=kubernetes.io/lifecycle=normal"
      suspended_processes           = ["AZRebalance"]
      additional_security_group_ids = [aws_security_group.worker_group_mgmt.id]
      bootstrap_extra_args          = "--enable-docker-bridge true"
      suspended_processes           = ["AZRebalance"]
    }
  ]

  worker_groups_launch_template = [
    {
      name                          = "spot-1a"
      override_instance_types       = ["t3.small"]
      autoscaling_enabled           = true
      protect_from_scale_in         = true
      spot_instance_pools           = 4
      asg_min_size                  = 0
      asg_max_size                  = 3
      public_ip                     = true
      additional_security_group_ids = [aws_security_group.worker_group_mgmt.id]
      bootstrap_extra_args          = "--enable-docker-bridge true"
      kubelet_extra_args            = "--node-labels=node-role.kubernetes.io/spot-worker=true --node-labels=spot=true --node-labels=kubernetes.io/lifecycle=spot"
      suspended_processes           = ["AZRebalance"]
    },
    {
      name                          = "spot-2a"
      override_instance_types       = ["t3.medium"]
      autoscaling_enabled           = true
      protect_from_scale_in         = true
      spot_instance_pools           = 4
      asg_min_size                  = 0
      asg_max_size                  = 3
      public_ip                     = true
      additional_security_group_ids = [aws_security_group.worker_group_mgmt.id]
      bootstrap_extra_args          = "--enable-docker-bridge true"
      kubelet_extra_args            = "--node-labels=node-role.kubernetes.io/spot-worker=true --node-labels=spot=true --node-labels=kubernetes.io/lifecycle=spot"
      suspended_processes           = ["AZRebalance"]
    },
  ]

  map_roles                            = var.map_roles
  map_users                            = var.map_users
  map_accounts                         = var.map_accounts
}