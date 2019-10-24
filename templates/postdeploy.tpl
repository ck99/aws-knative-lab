DEPLOYED!

Next Steps:
 1. Update kubectl config:
    KUBECONFIG=~/.kube/config:kubeconfig_${cluster_name} kubectl config view --flatten > ~/.kube/mergedkub && mv ~/.kube/mergedkub ~/.kube/config
    kubectl config use-context eks_${cluster_name}

 2. Install and init helm / tiller:
    kubectl create -f k8s/helm-rbac-config.yaml
    helm init --service-account tiller --history-max 200

 3. Activate cluster-autoscaling:
    helm install stable/cluster-autoscaler --name cluster-autoscaler --namespace kube-system --values=./k8s/cluster-autoscaler-values.yaml
    helm install stable/k8s-spot-termination-handler --name spot-termination-handler --namespace kube-system
    helm install stable/k8s-spot-rescheduler --name spot-rescheduler --set rbac.create=true --namespace kube-system

 4. Install knative
    helm repo add tm https://storage.googleapis.com/triggermesh-charts
    helm repo update
    helm install tm/knative --name knative