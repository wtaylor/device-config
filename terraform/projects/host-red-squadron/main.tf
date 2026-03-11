locals {
  node_name       = "red-one"
  root_disk_store = "local-zfs"
}

module "proxmox-metrics-user" {
  source                  = "../../modules/proxmox-metrics-user"
  credentials_secret_name = "terraform/host-red-squadron/outputs/proxmox-metrics-user"
}
