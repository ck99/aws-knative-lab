#!/usr/bin/env bash

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/

sudo apt-get update && sudo apt-get install docker.io -y
sudo gpasswd -a ubuntu docker
newgrp docker << EOF
sudo minikube start \
  --kubernetes-version=v1.12.0 \
  --vm-driver=none \
  --extra-config=apiserver.enable-admission-plugins="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook"

sudo chown -R $USER $HOME/.kube $HOME/.minikube

wget https://get.helm.sh/helm-v2.15.0-linux-amd64.tar.gz
tar xvzf helm-v2.15.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/
rm -rf linux-amd64

helm init

export ISTIO_VERSION=1.1.7
curl -L https://git.io/getLatestIstio | sh -
cd istio-${ISTIO_VERSION}
for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
cat <<ENDISTIO | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
 name: istio-system
 labels:
   istio-injection: disabled
ENDISTIO

helm template --namespace=istio-system \
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

kubectl apply -f istio-lean.yaml

EOF

####
####
#   Deployment.apps "istio-pilot" is invalid: spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values: Required value: must be specified when `operator` is 'In' or 'NotIn'
####
####


