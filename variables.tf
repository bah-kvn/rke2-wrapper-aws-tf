variable "cluster_name" {
  type        = string
  description = "The name of the cluster"
}

variable "vpc_id" {
  type        = string
  description = "The AWS VPC id where the cluster will be deployed"
}

variable "subnets" {
  type        = list(string)
  description = "The subnet ids where the control plane and nodepool nodes  will be deployed"
}

variable "rke2_version" {
  type        = string
  description = "RKE2 version to deploy"
  default     = "v1.26.3+rke2r1"
}

variable "enable_ccm" {
  type        = bool
  description = "Whether or not to enable the AWS Cloud Controller Manager"
  default     = true
}

variable "control_plane" {
  type = object({
    # The AMI id for the control plane nodes
    ami = string
    # The instance type for the control plane nodes
    instance_type = string
    # The configuration for the root volume
    root_volume = map(string)
    extra_block_device_mappings = list(map(string))
  })
}

variable "nodepools" {
  type = list(object({
    name          = string
    ami           = string
    instance_type = string
    asg = object({
      min                  = number
      max                  = number
      desired              = number
      termination_policies = list(string)
    })
    root_volume = map(string)
    extra_block_device_mappings = list(map(string))
  }))
  default     = []
  description = "A list of agent nodepools to configure."

  #TODO: add validation of default_storage has the keys required for the block_device_mappings input
}

variable "add_ons" {
  type = object({
    # the directory with the Kustomization file to be applied
    directory = string
    # environment variables to set during execution of the kustomize|kubectl apply command
    environment = map(string)
  })
  description = "The cluster add-ons configuration to apply"
}

variable "ccm_external" {
  type        = bool
  description = "True indicates the external cloud provider is to be used"
  default     = true
}

variable "pre_userdata" {
  description = "Custom userdata to run immediately before rke2 node attempts to join cluster, after required rke2, dependencies are installed"
  type        = string
  default     = ""
}

variable "rke2_config" {
  description = "Additional configuration for config.yaml"
  type        = string
  default     = ""
}

