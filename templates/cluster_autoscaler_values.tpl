rbac:
  create: true

cloudProvider: aws
awsRegion: ${region}

autoDiscovery:
  clusterName: ${cluster_name}
  enabled: true

nodeSelector:
  kubernetes.io/lifecycle: spot

extraArgs:
  skip-nodes-with-system-pods: false
  skip-nodes-with-local-storage: false
  scale-down-unneeded-time: 2m
  scale-down-delay-after-add: 2m
  scale-down-unready-time: 2m