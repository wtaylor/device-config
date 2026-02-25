locals {
  root_disk_store  = "local-zfs"
  ssd_volume_store = "local-zfs"
  dns_server       = "172.28.0.1"
  node_name        = "tardis"
  ignition_file    = "./files/butane/main.ign"
}

resource "proxmox_virtual_environment_file" "ignition" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = local.node_name

  source_file {
    path      = local.ignition_file
    file_name = "container-services.ign"
  }

  lifecycle {
    replace_triggered_by = [terraform_data.ignition_hash]
  }
}

resource "terraform_data" "ignition_hash" {
  input = filemd5(local.ignition_file)
}

resource "proxmox_virtual_environment_vm" "vm" {
  name = "container-services"
  tags = ["terraform", "podman", "coreos", "ignition"]

  node_name = local.node_name
  vm_id     = 104

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  boot_order = ["scsi0"]

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

  initialization {
    datastore_id = local.root_disk_store
    dns {
      servers = [local.dns_server]
    }
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.ignition.id
  }

  disk {
    file_id      = "local:iso/coreos.img"
    datastore_id = local.root_disk_store

    interface = "scsi0"
    serial    = "viscsi-root"
    size      = 128
    backup    = true
    ssd       = true
    discard   = "on"
  }

  # Caddy - Data
  disk {
    datastore_id = local.ssd_volume_store
    interface    = "scsi1"
    serial       = "viscsi-caddy-data"
    size         = 1
    backup       = true
    ssd          = true
    discard      = "on"
  }

  # Vector - Data
  disk {
    datastore_id = local.ssd_volume_store
    interface    = "scsi2"
    serial       = "viscsi-vector-data"
    size         = 16
    backup       = true
    ssd          = true
    discard      = "on"
  }

  # Victoria Logs - Data
  disk {
    datastore_id = local.ssd_volume_store
    interface    = "scsi3"
    serial       = "viscsi-vl-data"
    size         = 128
    backup       = true
    ssd          = true
    discard      = "on"
  }

  # Victoria Metrics - Data
  disk {
    datastore_id = local.ssd_volume_store
    interface    = "scsi4"
    serial       = "viscsi-vm-data"
    size         = 128
    backup       = true
    ssd          = true
    discard      = "on"
  }

  # Grafana - Data
  disk {
    datastore_id = local.ssd_volume_store
    interface    = "scsi5"
    serial       = "viscsi-grafana-data"
    size         = 16
    backup       = true
    ssd          = true
    discard      = "on"
  }

  # Versity Gateway - Data
  disk {
    datastore_id = local.ssd_volume_store
    interface    = "scsi6"
    serial       = "viscsi-vs3-data"
    size         = 1024
    backup       = true
    ssd          = true
    discard      = "on"
  }
}

