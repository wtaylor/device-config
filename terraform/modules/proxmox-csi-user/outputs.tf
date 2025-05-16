output "api_token_id" {
  value = proxmox_virtual_environment_user_token.csi_user_token.id
}
output "api_token" {
  sensitive = true
  value     = proxmox_virtual_environment_user_token.csi_user_token.value
}
