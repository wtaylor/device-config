resource "proxmox_virtual_environment_role" "csi" {
  role_id = "CSI"

  privileges = [
    "VM.Audit",
    "VM.Config.Disk",
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.Audit",
  ]
}

resource "proxmox_virtual_environment_user" "csi_user" {
  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.csi.role_id
  }

  comment = "Managed by Terraform"
  user_id = "${var.proxmox_csi_username}@pve"
}

resource "proxmox_virtual_environment_user_token" "csi_user_token" {
  comment               = "Managed by Terraform"
  token_name            = "csi"
  privileges_separation = false
  user_id               = proxmox_virtual_environment_user.csi_user.user_id
}
