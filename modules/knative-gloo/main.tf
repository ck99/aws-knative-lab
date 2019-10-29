terraform {
  required_version = ">= 0.12.0"
}

provider "null" {
  version = "~> 2.1"
}

provider "helm" {
  version = "~> 0.10"
  max_history = 200
  service_account = "tiller"
  kubernetes {
    config_path = var.k8s_config_file
  }
}

data "helm_repository" "gloo" {
  name = "gloo"
  url  = "https://storage.googleapis.com/solo-public-helm"
}

locals {
  image_tag       = "0.20.11"
  knative_version = "0.9.0"
  kubectl_cmd = "kubectl --kubeconfig='${var.k8s_config_file}' "
}

resource "helm_release" "gloo_with_knative" {
  name       = "knative-gloo"
  repository = data.helm_repository.gloo.metadata[0].name
  chart      = "gloo/gloo"
  namespace  = "gloo-system"

  set {
    name     = "accessLogger.image.tag"
    value    = local.image_tag
  }

  set {
    name     = "discovery.deployment.image.tag"
    value    = local.image_tag
  }

  set {
    name     = "gateway.certGenJob.image.tag"
    value    = local.image_tag
  }

  set {
    name     = "gateway.conversionJob.image.tag"
    value    = local.image_tag
  }

  set {
    name     = "gateway.deployment.image.tag"
    value    = local.image_tag
  }

  set {
    name     = "gatewayProxies.gatewayProxyV2.podTemplate.image.tag"
    value    = local.image_tag
  }

  set {
    name     = "gloo.deployment.image.tag"
    value    = local.image_tag
  }

  set {
    name     = "discovery.fdsMode"
    value    = "WHITELIST"
  }

  set {
    name     = "gateway.enabled"
    value    = "false"
  }

  set {
    name     = "ingress.deployment.image.repository"
    value    = "ingress"
  }

  set {
    name     = "ingress.deployment.image.tag"
    value    = local.image_tag
  }

  set {
    name     = "ingress.deployment.replicas"
    value    = 1
  }

  set {
    name     = "ingress.deployment.resources"
    value    = "null"
  }

  set {
    name     = "settings.integrations.knative.enabled"
    value    = true
  }

  set {
    name     = "settings.integrations.knative.proxy.httpPort"
    value    = 80
  }

  set {
    name     = "settings.integrations.knative.proxy.httpsPort"
    value    = 443
  }

  set {
    name     = "settings.integrations.knative.proxy.image.repository"
    value    = "gloo-envoy-wrapper"
  }

  set {
    name     = "settings.integrations.knative.proxy.image.tag"
    value    = local.image_tag
  }

  set {
    name     = "settings.integrations.knative.proxy.replicas"
    value    = 1
  }

  set {
    name     = "settings.integrations.knative.proxy.resources"
    value    = "null"
  }

  set {
    name     = "settings.integrations.knative.version"
    value    = local.knative_version
  }
}

resource "null_resource" "knative_custom_resource_definitions" {
  provisioner "local-exec" {
    command = <<EOS
${local.kubectl_cmd} apply --selector knative.dev/crd-install=true \
   --filename https://github.com/knative/serving/releases/download/v0.9.0/serving.yaml \
   --filename https://github.com/knative/eventing/releases/download/v0.9.0/release.yaml \
   --filename https://github.com/knative/serving/releases/download/v0.9.0/monitoring.yaml

EOS
    interpreter = ["/bin/sh", "-c"]
  }

  provisioner "local-exec" {
    when = "destroy"
    command = <<EOS
${local.kubectl_cmd} delete \
   --filename https://github.com/knative/serving/releases/download/v0.9.0/serving.yaml \
   --filename https://github.com/knative/eventing/releases/download/v0.9.0/release.yaml \
   --filename https://github.com/knative/serving/releases/download/v0.9.0/monitoring.yaml
exit 0
EOS
    interpreter = ["/bin/sh", "-c"]
  }

}

resource "null_resource" "knative_install" {
  provisioner "local-exec" {
    command = <<EOS
${local.kubectl_cmd} apply \
   --filename https://github.com/knative/serving/releases/download/v0.9.0/serving.yaml \
   --filename https://github.com/knative/eventing/releases/download/v0.9.0/release.yaml \
   --filename https://github.com/knative/serving/releases/download/v0.9.0/monitoring.yaml

EOS
    interpreter = ["/bin/sh", "-c"]
  }

  provisioner "local-exec" {
    when = "destroy"
    command = <<EOS
${local.kubectl_cmd} delete \
   --filename https://github.com/knative/serving/releases/download/v0.9.0/serving.yaml \
   --filename https://github.com/knative/eventing/releases/download/v0.9.0/release.yaml \
   --filename https://github.com/knative/serving/releases/download/v0.9.0/monitoring.yaml
exit 0
EOS
    interpreter = ["/bin/sh", "-c"]
  }
  depends_on = [null_resource.knative_custom_resource_definitions]
}