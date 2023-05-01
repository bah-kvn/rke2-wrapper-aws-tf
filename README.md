# BSF RKE2 AWS TF

This module deploys a Booz Allen Software Factory RKE2 cluster and configure multiple aspects of the cluster.

This module is a wrapper for the [bsf-rke2-aws-tf](), providing an abstraction to simplify the deployment of a fully configured platform.

* **Control Plane** - configure the RKE2 API server nodes
* **Agent Nodepools** - provide a list of nodepools to configure
* **Add-Ons** - a list of helm charts that will be deployed via GitOps through registration with Flux
