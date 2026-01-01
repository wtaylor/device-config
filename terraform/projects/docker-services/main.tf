locals {
  root_disk_store    = "local-zfs"
  ssd_volume_store   = "local-zfs"
  large_volume_store = "bigmt-vmdata"
  dns_server         = "172.28.0.1"
  default_gateway    = "172.28.0.1"
}

resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "tardis"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: docker-services
    package_update: true
    package_upgrade: true
    packages:
    - qemu-guest-agent
    - python3
    - python3-pip
    users:
    - default
    - name: wtaylor
      groups: sudo
      shell: /bin/bash
      ssh-authorized-keys:
      - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICoiyox/Pky3ViojzBlOOes3yGHgDRZ+OUogUc7h1W3O wtaylor@nebuchadnezzar"
      - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJMpF3SQqNbnqHAEMTjbcyErL82dymZM1B1Iu5MbZybd wtaylor@nostromo"
      sudo: ALL=(ALL) NOPASSWD:ALL
    EOF

    file_name = "docker-services.cloud-init.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "docker_vm" {
  name = "docker-services"
  tags = ["terraform", "docker", "debian"]

  node_name = "tardis"
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

  disk {
    import_from = "local:import/debian-trixie.raw"

    datastore_id = local.root_disk_store
    interface    = "scsi0"
    serial       = "viscsi-root"
    size         = 256
    backup       = true
    ssd          = true
    discard      = "on"
  }

  # Traefik - Data
  disk {
    datastore_id = local.ssd_volume_store
    interface    = "scsi1"
    serial       = "viscsi-traefik-data"
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

  # SeaweedFS - SSD Volume Data
  disk {
    datastore_id = local.ssd_volume_store
    interface    = "scsi6"
    serial       = "viscsi-sfs-ssdv-data"
    size         = 1024
    backup       = true
    ssd          = true
    discard      = "on"
  }

  # SeaweedFS - HDD Volume Data
  disk {
    datastore_id = local.large_volume_store
    interface    = "scsi7"
    serial       = "viscsi-sfs-hddv-data"
    size         = 1024
    backup       = true
    ssd          = true
    discard      = "on"
  }
  # SeaweedFS - Metadata
  disk {
    datastore_id = local.ssd_volume_store
    interface    = "scsi8"
    serial       = "viscsi-sfs-m-data"
    size         = 64
    backup       = true
    ssd          = true
    discard      = "on"
  }
  # OpenBau - Data
  disk {
    datastore_id = local.ssd_volume_store
    interface    = "scsi9"
    serial       = "viscsi-openbau-data"
    size         = 16
    backup       = true
    ssd          = true
    discard      = "on"
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

    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }
}

