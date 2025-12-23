resource "proxmox_virtual_environment_vm" "node_vm" {
  name = "tardis-docker"
  tags = ["terraform", "docker"]

  node_name = "tardis"
  vm_id     = 104

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  boot_order = ["scsi0", "ide0", "net0"]

  agent {
    enabled = true
  }

  cpu {
    cores = 6
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 16384
    floating  = 16384
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  cdrom {
    interface = "ide0"
    file_id   = var.vm_installer_cdrom_file_id
  }

  disk {
    datastore_id = local.datastore_id
    interface    = "scsi0"
    size         = 256
    serial       = "viscsi-001"
    backup       = true
    replicate    = true
    ssd          = true
    discard      = "on"
  }

  initialization {
    datastore_id = local.datastore_id
    interface    = "ide2"
    dns {
      servers = var.node_dns_servers
    }
    ip_config {
      ipv4 {
        address = "${var.node_ip}/22"
        gateway = var.node_default_gateway
      }
    }
  }
}

