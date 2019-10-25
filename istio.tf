resource "null_resource" "istio_source" {
  provisioner "local-exec" {
    command = <<EOS
export ISTIO_VERSION=${local.istio_version}
if [ ! -d istio-${local.istio_version} ]; then
  curl -L https://git.io/getLatestIstio | sh -
fi
EOS
    working_dir = "./k8s"
    interpreter = ["/bin/sh", "-c"]
  }

  depends_on = [helm_release.cluster_autoscaler, helm_release.spot_termination_handler, helm_release.spot_rescheduler]
  triggers = {
    k8s_endpoint = module.eks.cluster_endpoint
  }
}

resource "null_resource" "istio_custom_resource_definitions" {
  provisioner "local-exec" {
    command = <<EOS
for i in install/kubernetes/helm/istio-init/files/crd*yaml; do ${local.kubectl_cmd} apply -f $${i}; done
cat <<ENDISTIO | ${local.kubectl_cmd} apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: istio-system
 labels:
   istio-injection: disabled
ENDISTIO
EOS

    working_dir = "./k8s/istio-${local.istio_version}"
    interpreter = ["/bin/sh", "-c"]
  }
  depends_on = [null_resource.istio_source]
}

resource "null_resource" "istio_lean_install" {
  provisioner "local-exec" {
    command = <<EOS
${local.helm_cmd} template --namespace=istio-system \
  --set prometheus.enabled=false \
  --set mixer.enabled=false \
  --set mixer.policy.enabled=false \
  --set mixer.telemetry.enabled=false \
  `# Pilot doesn't need a sidecar.` \
  --set pilot.sidecar=false \
  --set pilot.resources.requests.memory=128Mi \
  `# Disable galley (and things requiring galley).` \
  --set galley.enabled=false \
  --set global.useMCP=false \
  `# Disable security / policy.` \
  --set security.enabled=false \
  --set global.disablePolicyChecks=true \
  `# Disable sidecar injection.` \
  --set sidecarInjectorWebhook.enabled=false \
  --set global.proxy.autoInject=disabled \
  --set global.omitSidecarInjectorConfigMap=true \
  `# Set gateway pods to 1 to sidestep eventual consistency / readiness problems.` \
  --set gateways.istio-ingressgateway.autoscaleMin=1 \
  --set gateways.istio-ingressgateway.autoscaleMax=1 \
  `# Set pilot trace sampling to 100%` \
  --set pilot.traceSampling=100 \
  install/kubernetes/helm/istio \
  > ./istio-lean.yaml

${local.kubectl_cmd} apply -f istio-lean.yaml

EOS
    working_dir = "./k8s/istio-${local.istio_version}"
    interpreter = ["/bin/sh", "-c"]
  }
  depends_on = [null_resource.istio_custom_resource_definitions]
}

resource "null_resource" "istio_local_gateway" {
  provisioner "local-exec" {
    command = <<EOS
${local.helm_cmd} template --namespace=istio-system \
  --set gateways.custom-gateway.autoscaleMin=1 \
  --set gateways.custom-gateway.autoscaleMax=1 \
  --set gateways.custom-gateway.cpu.targetAverageUtilization=60 \
  --set gateways.custom-gateway.labels.app='cluster-local-gateway' \
  --set gateways.custom-gateway.labels.istio='cluster-local-gateway' \
  --set gateways.custom-gateway.type='ClusterIP' \
  --set gateways.istio-ingressgateway.enabled=false \
  --set gateways.istio-egressgateway.enabled=false \
  --set gateways.istio-ilbgateway.enabled=false \
  install/kubernetes/helm/istio \
  -f install/kubernetes/helm/istio/example-values/values-istio-gateways.yaml \
  | sed -e "s/custom-gateway/cluster-local-gateway/g" -e "s/customgateway/clusterlocalgateway/g" \
  > ./istio-local-gateway.yaml

${local.kubectl_cmd} apply -f istio-local-gateway.yaml

EOS
    working_dir = "./k8s/istio-${local.istio_version}"
    interpreter = ["/bin/sh", "-c"]
  }
  depends_on = [null_resource.istio_lean_install]
}