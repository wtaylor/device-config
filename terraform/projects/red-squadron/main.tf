locals {
  talos_version = "v1.10.1"
}

data "talos_image_factory_extensions_versions" "red_squadron" {
  talos_version = local.talos_version
  filters = {
    names = [
      "cloudflared",
      "gasket-driver",
      "i915",
      "intel-ice-firmware",
      "intel-ucode",
      "iscsi-tools",
      "mei",
      "nut-client",
      "qemu-guest-agent",
      "thunderbolt",
      "tailscale",
    ]
  }
}

resource "talos_image_factory_schematic" "red_squadron" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.red_squadron.extensions_info.*.name
        }
      }
    }
  )
}

data "talos_image_factory_urls" "red_squadron" {
  talos_version = local.talos_version
  schematic_id  = talos_image_factory_schematic.red_squadron.id
  architecture  = "amd64"
  platform      = "nocloud"
}

resource "proxmox_virtual_environment_download_file" "talos_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "red-one"
  file_name    = "talos-nocloud-amd64.iso"

  url = data.talos_image_factory_urls.red_squadron.urls.iso
}

resource "proxmox_virtual_environment_hardware_mapping_pci" "red_squadron_igpu" {
  comment = "Mapping for Intel integrated GPU"
  name    = "intel-igpu"
  map = [
    {
      id           = "8086:46a3"
      iommu_group  = 0
      node         = "red-one"
      path         = "0000:00:02.0"
      subsystem_id = "8086:0300"
    },
  ]
}

resource "proxmox_virtual_environment_hardware_mapping_pci" "red_squadron_coral" {
  comment = "Mapping for Google Coral PCIe Accelerator"
  name    = "coral-pcie"
  map = [
    {
      id           = "1ac1:089a"
      iommu_group  = 13
      node         = "red-one"
      path         = "0000:04:00.0"
      subsystem_id = "1ac1:0880"
    },
  ]
}

resource "proxmox_virtual_environment_vm" "red_one_talos" {
  name = "red-one-talos"
  tags = ["kubernetes", "talos", "terraform"]

  node_name = "red-one"
  vm_id     = 101

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
  }

  cpu {
    cores = 8
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 32768
    floating  = 32768
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  cdrom {
    interface = "ide0"
    file_id   = proxmox_virtual_environment_download_file.talos_iso.id
  }

  hostpci {
    device  = "hostpci0"
    mapping = proxmox_virtual_environment_hardware_mapping_pci.red_squadron_igpu.name
    pcie    = true
  }

  hostpci {
    device  = "hostpci1"
    mapping = proxmox_virtual_environment_hardware_mapping_pci.red_squadron_coral.name
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    size         = 256
    backup       = true
    replicate    = true
    discard      = "on"
  }

  initialization {
    datastore_id = "local-zfs"
    interface    = "ide2"
    dns {
      servers = ["172.28.0.1"]
    }
    ip_config {
      ipv4 {
        address = "172.28.3.1/22"
        gateway = "172.28.0.1"
      }
    }
  }
}
