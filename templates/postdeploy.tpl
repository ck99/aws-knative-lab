DEPLOYED!

Next Steps:
 1. Update kubectl config:
    KUBECONFIG=~/.kube/config:kubeconfig_${cluster_name} kubectl config view --flatten > ~/.kube/mergedkub && mv ~/.kube/mergedkub ~/.kube/config
    kubectl config use-context eks_${cluster_name}

 2. Install knative
    helm repo add tm https://storage.googleapis.com/triggermesh-charts
    helm repo update
    helm install tm/knative --name knative