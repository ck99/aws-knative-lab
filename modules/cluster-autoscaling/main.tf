terraform {
  required_version = ">= 0.12.0"
}

provider "helm" {
  version = "~> 0.10"
  max_history = 200
  service_account = "tiller"
  kubernetes {
    config_path = var.k8s_config_file
  }
}

resource "helm_release" "cluster_autoscaler" {
  name      = "cluster-autoscaler"
  chart     = "stable/cluster-autoscaler"
  namespace = "kube-system"

  set {
    name  = "rbac.create"
    value = true
  }

  set {
    name  = "cloudprovider"
    value = "aws"
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "autoDiscovery.enabled"
    value = true
  }

  set {
    name  = "nodeSelector.kubernetes\\.io/lifecycle"
    value = "spot"
  }

  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = false
  }

  set {
    name  = "extraArgs.skip-nodes-with-local-storage"
    value = false
  }

  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = "20m"
  }

  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = "20m"
  }

  set {
    name  = "extraArgs.scale-down-unready-time"
    value = "20m"
  }

  set {
    name  = "extraArgs.expander"
    value = "least-waste"
  }

}

resource "helm_release" "spot_termination_handler" {
  name = "spot-termination-handler"
  chart = "stable/k8s-spot-termination-handler"
  namespace = "kube-system"
}

resource "helm_release" "spot_rescheduler" {
  name = "spot-rescheduler"
  chart = "stable/k8s-spot-rescheduler"
  namespace = "kube-system"

  set {
    name  = "rbac.create"
    value = true
  }
}

