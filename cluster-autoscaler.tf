provider "kubernetes" {
  host = module.eks.cluster_endpoint
  config_path = module.eks.kubeconfig_filename
  load_config_file = module.eks.cluster_endpoint != "" ? true : false
}

provider "helm" {
  version = "~> 0.10"
  max_history = 200
  service_account = "tiller"
  kubernetes {
    host = module.eks.cluster_endpoint
    config_path = module.eks.kubeconfig_filename
    load_config_file = module.eks.cluster_endpoint != "" ? true : false
  }
}

resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = "tiller-binding"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "kube-system"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "helm_release" "cluster_autoscaler" {
  name      = "cluster-autoscaler"
  chart     = "stable/cluster-autoscaler"
  namespace = "kube-system"

  depends_on = ["kubernetes_service_account.tiller", "kubernetes_cluster_role_binding.tiller"]

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
    value = local.cluster_name
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
    value = "2m"
  }

  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = "2m"
  }

  set {
    name  = "extraArgs.scale-down-unready-time"
    value = "2m"
  }

  set {
    name  = "extraArgs.expander"
    value = "most-pods"
  }

}

resource "helm_release" "spot_termination_handler" {
  name = "spot-termination-handler"
  chart = "stable/k8s-spot-termination-handler"
  namespace = "kube-system"
  depends_on = ["kubernetes_service_account.tiller", "kubernetes_cluster_role_binding.tiller"]
}

resource "helm_release" "spot_rescheduler" {
  name = "spot-rescheduler"
  chart = "stable/k8s-spot-rescheduler"
  namespace = "kube-system"
  depends_on = ["kubernetes_service_account.tiller", "kubernetes_cluster_role_binding.tiller"]

  set {
    name  = "rbac.create"
    value = true
  }
}