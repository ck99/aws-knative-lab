# Update kubeconfig
 * `aws eks update-kubeconfig --name knative-lab-<ID>`
 
 OR

 * ```
   function kmerge() {
     KUBECONFIG=~/.kube/config:$1 kubectl config view --flatten > ~/.kube/mergedkub && mv ~/.kube/mergedkub ~/.kube/config
   }
   
   kmerge ./kubeconfig_knative-lab-<ID>
# Init Helm / Tiller
 * `kubectl create -f k8s/helm-rbac-config.yaml`
 * `helm init --service-account tiller --history-max 200`

# Activate AutoScaling

 * `helm install stable/cluster-autoscaler --name cluster-autoscaler --values=./k8s/cluster-autoscaler-values.yaml`
 
# Activate Spot Instance Termination Handler

 * `helm install stable/k8s-spot-termination-handler --name spot-termination-handler --namespace kube-system`
 

# Deploy istio / knative