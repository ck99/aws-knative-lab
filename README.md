| Item          | MAX Qty         | Item $/hr  | MAX Total $/hr | EST Total $/hr |
| ------------- |-------------:| -----:|-----: |----:|
| EKS Service   | 1        | $0.20 | $0.20 | $0.20 |
| OnDemand (`t3.small`)     | 2      |   $0.0228 | $0.05 | $0.03 |
| | | | $0.25 | $0.23 |


| Item          | MAX Qty         | Spot $/hr  | OnDemand $/hr | EST Total $/hr |
| ------------- |-------------:| -----:|-----: |----:|
| Spot (`t3.small`) | 5  | $0.0068 |  $0.0228 |  $0.03 |
| Spot (`t3.medium`) | 5  | $0.0137 |  $0.0456 |  $0.07 |
| Avg. Spot | 5 | $0.0103 | $0.0342 | $0.05 - $0.17 |

Total: $0.40 / hr (+storage)


Requirements:

* terraform
* aws-iam-authenticator

https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html