# Init Helm / Tiller
 * `kubectl --kubeconfig ./kubeconfig_knative-lab-<ID> create -f k8s/helm-rbac-config.yaml`
 * `helm --kubeconfig ./kubeconfig_knative-lab-<ID> init --service-account tiller --history-max 200`

# Activate AutoScaling

 * `helm --kubeconfig ./kubeconfig_knative-lab-<ID> install stable/cluster-autoscaler --values=./cluster-autoscaler-values.yaml`
 
# Activate Spot Instance Termination Handler

 * `helm --kubeconfig ./kubeconfig_knative-lab-<ID> install stable/k8s-spot-termination-handler --namespace kube-system`
 

# Deploy istio / knative