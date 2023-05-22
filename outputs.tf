output "cluster_auth" {
  value     = data.external.cluster_auth.result
  sensitive = true
}

output "rke2_config" {
  value = var.rke2_config
}

output "pre_userdata" {
  value = var.pre_userdata
}

output "rke2" {
  value = module.rke2
}

