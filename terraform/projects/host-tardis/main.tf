locals {
  node_name       = "tardis"
  root_disk_store = "local-zfs"
}

module "proxmox-metrics-user" {
  source                  = "../../modules/proxmox-metrics-user"
  credentials_secret_name = "terraform/host-tardis/outputs/proxmox-metrics-user"
}
