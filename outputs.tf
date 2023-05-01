output "cluster_auth" {
  value     = data.external.cluster_auth.result
  sensitive = true
}

output "rke2" {
  value = module.rke2
}