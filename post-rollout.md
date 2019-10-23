# Update kubeconfig
 * `aws eks update-kubeconfig --name knative-lab-<ID>`

# Init Helm / Tiller
 * `kubectl create -f k8s/helm-rbac-config.yaml`
 * `helm init --service-account tiller --history-max 200`

# Activate AutoScaling

 * `helm install stable/cluster-autoscaler --values=./cluster-autoscaler-values.yaml`
 
# Activate Spot Instance Termination Handler

 * `helm install stable/k8s-spot-termination-handler --namespace kube-system`
 

# Deploy istio / knative