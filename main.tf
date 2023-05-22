locals {
  tags = {
    "terraform" = "true",
    "cluster"   = var.cluster_name,
  }
}

# Key Pair for node
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_pem" {
  filename        = "${var.cluster_name}.pem"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0600"
}

module "rke2" {
  source = "git::https://github.com/boozallen/rke2-aws-tf.git?ref=develop"

  rke2_version = var.rke2_version
  rke2_config  = var.rke2_config
  pre_userdata = var.pre_userdata
  ccm_external = var.ccm_external
  cluster_name = var.cluster_name
  vpc_id       = var.vpc_id
  subnets      = var.subnets
  enable_ccm   = var.enable_ccm

  ami                         = var.control_plane.ami
  ssh_authorized_keys         = [tls_private_key.ssh.public_key_openssh]
  instance_type               = var.control_plane.instance_type
  controlplane_internal       = false # Note this defaults to best practice of true, but is explicitly set to public for demo purposes
  servers                     = 3
  associate_public_ip_address = true
  block_device_mappings       = var.control_plane.root_volume
  extra_block_device_mappings = var.control_plane.extra_block_device_mappings
  tags = local.tags
}

# generate the nodepools defined by the user
# TODO: allow user to define rke2 config file
module "agents" {
  for_each = { for nodepool in var.nodepools : nodepool.name => nodepool }

  source = "git::https://github.com/boozallen/rke2-aws-tf.git//modules/agent-nodepool?ref=develop"

  ccm_external = var.ccm_external
  rke2_version = var.rke2_version
  rke2_config  = var.rke2_config
  pre_userdata = var.pre_userdata
  name       = each.value.name
  vpc_id     = var.vpc_id
  subnets    = var.subnets
  enable_ccm = var.enable_ccm

  ami                   = each.value.ami
  ssh_authorized_keys   = [tls_private_key.ssh.public_key_openssh]
  instance_type         = each.value.instance_type
  cluster_data          = module.rke2.cluster_data
  asg                   = each.value.asg
  block_device_mappings = each.value.root_volume
  extra_block_device_mappings = each.value.extra_block_device_mappings
  associate_public_ip_address = true

#  rke2_config = yamlencode({
#    node-label = ["nodepool=${each.value.name}"]
#  })

  tags = merge(local.tags, { nodepool = each.value.name })
}

# allow SSH from BAH CIDRs
resource "aws_security_group_rule" "quickstart_ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = module.rke2.cluster_data.cluster_sg
  type              = "ingress"
  cidr_blocks       = ["128.229.4.0/24", "156.80.4.0/24", "128.229.67.0/24"]
}

# Example method of fetching kubeconfig from state store, requires aws cli and bash locally
resource "random_string" "kubeconfig_suffix" {
  length = 4
  special = false
}

locals {
  kubeconfig = abspath("rke2-${var.cluster_name}-${random_string.kubeconfig_suffix.result}.yaml")
}

resource "null_resource" "kubeconfig" {
  depends_on = [module.rke2]

  # just always rerun this command
  triggers = {
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "aws s3 cp ${module.rke2.kubeconfig_path} ${local.kubeconfig}"
  }
}

# fetch cluster auth data for outputs
data "external" "cluster_auth" {
  depends_on = [null_resource.kubeconfig]
  program    = ["bash", "-c", abspath("scripts/fetch-auth.sh")]
  query = {
    kubeconfig = local.kubeconfig
  }
}

resource "null_resource" "wait_for_cluster" {
  depends_on = [null_resource.kubeconfig]
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      TRIES = 5
      SLEEP = 5
    }
    command = "for i in {1..$TRIES}; do kubectl --kubeconfig ${local.kubeconfig} get nodes && break || sleep $SLEEP; done"
  }
}

# install add ons
resource "null_resource" "add_ons" {
  depends_on = [null_resource.wait_for_cluster]

  # just always rerun this command
  triggers = {
    timestamp = timestamp()
  }

  # we run this twice because sometimes the ordering is funky
  provisioner "local-exec" {
    interpreter = ["bash"]
    environment = merge(var.add_ons.environment, {
      ADD_ONS    = var.add_ons.directory
      KUBECONFIG = local.kubeconfig
      TRIES      = 3
      SLEEP      = 5
    })
    command = abspath("scripts/install-add-ons.sh")
  }
}
