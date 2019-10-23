rbac:
  create: true

cloudProvider: aws
awsRegion: ${region}

autoDiscovery:
  clusterName: ${cluster_name}
  enabled: true

nodeSelector:
  kubernetes.io/lifecycle: spot