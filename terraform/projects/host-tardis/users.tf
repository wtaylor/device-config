resource "proxmox_virtual_environment_group" "admins" {
  group_id = "admins"
  comment  = "Full access administrators. Managed by Terraform."

  acl {
    path      = "/"
    propagate = true
    role_id   = "Administrator"
  }
}

data "vault_kv_secret_v2" "credentials_wtaylor" {
  mount = "kv"
  name  = "system/device-config/wtaylor-proxmox-credentials"
}

resource "proxmox_virtual_environment_user" "wtaylor" {
  user_id  = "wtaylor@pam"
  password = data.vault_kv_secret_v2.credentials_wtaylor.data.password
  comment  = "Managed by Terraform"

  email      = "me@willtaylor.info"
  first_name = "William"
  last_name  = "Taylor"

  groups = ["admins"]
}
