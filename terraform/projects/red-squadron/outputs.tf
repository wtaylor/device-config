output "talos_client_config" {
  sensitive = true
  value     = data.talos_client_configuration.red_squadron_talos.talos_config
}

output "kubeconfig" {
  sensitive = true
  value     = talos_cluster_kubeconfig.red_squadron_talos.kubeconfig_raw
}

