data "proxmox_virtual_environment_role" "pve_auditor" {
  role_id = "PVEAuditor"
}

resource "random_password" "password" {
  length  = 16
  special = true
}

resource "proxmox_virtual_environment_user" "metrics_user" {
  acl {
    path      = "/"
    propagate = true
    role_id   = data.proxmox_virtual_environment_role.pve_auditor.role_id
  }

  comment  = "Managed by Terraform"
  user_id  = "metrics@pve"
  password = random_password.password.result
}

resource "proxmox_virtual_environment_user_token" "metrics_user_token" {
  comment               = "Managed by Terraform"
  token_name            = "metrics"
  privileges_separation = false
  user_id               = proxmox_virtual_environment_user.metrics_user.user_id
}

resource "vault_kv_secret_v2" "credentials_wtaylor" {
  mount = "kv"
  name  = var.credentials_secret_name
  data_json = jsonencode({
    username = proxmox_virtual_environment_user.metrics_user.user_id
    password = random_password.password.result
    tokenId  = proxmox_virtual_environment_user_token.metrics_user_token.id
    token    = replace(proxmox_virtual_environment_user_token.metrics_user_token.value, "${proxmox_virtual_environment_user_token.metrics_user_token.id}=", "")
  })
}
