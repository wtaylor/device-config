locals {
  node_name = "tardis"
}

resource "proxmox_virtual_environment_download_file" "omv_iso" {
  content_type   = "iso"
  datastore_id   = "local"
  node_name      = local.node_name
  file_name      = "openmediavault-amd64.iso"
  upload_timeout = 1800

  url = "https://sourceforge.net/projects/openmediavault/files/iso/7.4.17/openmediavault_7.4.17-amd64.iso"
}

resource "proxmox_virtual_environment_vm" "omv_vm" {
  name        = "nas-omv"
  description = "Home NAS running OpenMediaVault"
  tags        = ["omv", "terraform"]

  node_name = local.node_name
  vm_id     = 103

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  boot_order = ["scsi0", "ide0", "net0"]

  agent {
    enabled = true
  }
  stop_on_destroy = true

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
    floating  = 4096
  }

  cdrom {
    file_id   = proxmox_virtual_environment_download_file.omv_iso.id
    interface = "ide0"
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    size         = 64
    ssd          = true
    discard      = "on"
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi1"
    size         = 1024
    ssd          = true
    discard      = "on"
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  tpm_state {
    version      = "v2.0"
    datastore_id = "local-zfs"
  }
}

