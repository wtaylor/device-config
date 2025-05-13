locals {
  talos_version     = "v1.10.1"
  talos_cluster_vip = "172.28.2.10"
  talos_one = {
    ip               = "172.28.2.11"
    root_disk_serial = "viscsi-001"
  }
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
      subsystem_id = "8086:2212"
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
      subsystem_id = "1ac1:089a"
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
    serial       = local.talos_one.root_disk_serial
    datastore_id = "local-zfs"
    interface    = "scsi0"
    size         = 256
    backup       = true
    replicate    = true
    ssd          = true
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
        address = "${local.talos_one.ip}/22"
        gateway = "172.28.0.1"
      }
    }
  }
}

resource "time_sleep" "red_squadron_talos_one_init" {
  depends_on = [proxmox_virtual_environment_vm.red_one_talos]

  create_duration = "20s"
}

resource "talos_machine_secrets" "red_squadron_talos" {}

data "talos_machine_configuration" "red_squadron_talos_one" {
  cluster_name     = "red-squadron-talos"
  machine_type     = "controlplane"
  cluster_endpoint = "https://${local.talos_cluster_vip}:6443"
  machine_secrets  = talos_machine_secrets.red_squadron_talos.machine_secrets
}

resource "talos_machine_configuration_apply" "red_squadron_talos_one" {
  depends_on = [time_sleep.red_squadron_talos_one_init]

  client_configuration        = talos_machine_secrets.red_squadron_talos.client_configuration
  machine_configuration_input = data.talos_machine_configuration.red_squadron_talos_one.machine_configuration
  node                        = local.talos_one.ip
  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = data.talos_image_factory_urls.red_squadron.urls.installer
          disk  = "/dev/sda"
        }
        kernel = {
          modules = [{ name = "iptable_mangle" }, { name = "tun" }]
        }
        sysctls = {
          "net.ipv4.conf.all.src_valid_mark" = "1"
        }
        kubelet = {
          extraArgs = {
            rotate-server-certificates = true
          }
        }
        network = {
          interfaces = [{
            interface = "eth0"
            dhcp      = false
            addresses = ["${local.talos_one.ip}/22"]
            vip = {
              ip = local.talos_cluster_vip
            }
            routes = [{
              network = "0.0.0.0/0"
              gateway = "172.28.0.1"
            }]
          }]
        }
        logging = {
          destinations = [{
            endpoint = "udp://vector-server.willtaylor.info:6051/"
            format   = "json_lines"
          }]
        }
      }
      cluster = {
        allowSchedulingOnControlPlanes = true
        network = {
          cni = {
            name = "none"
          }
        }
        proxy = {
          disabled = true
        }
        apiServer = {
          certSANs = ["red-squadron-talos.willtaylor.info"]
        }
        extraManifests = [
          "https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/refs/tags/v0.9.1/deploy/standalone-install.yaml",
          "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml",
          "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml",
          "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml",
          "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml",
          "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml",
        ]
        inlineManifests = [{
          name     = "cilium-install-job"
          contents = file("${path.module}/files/cilium-install-job.yaml")
        }]
      }
    })
  ]
}

resource "talos_machine_bootstrap" "red_squadron_talos_one" {
  depends_on = [
    talos_machine_configuration_apply.red_squadron_talos_one
  ]
  node                 = local.talos_one.ip
  client_configuration = talos_machine_secrets.red_squadron_talos.client_configuration
}

data "talos_client_configuration" "red_squadron_talos" {
  cluster_name         = "red-squadron-talos"
  client_configuration = talos_machine_secrets.red_squadron_talos.client_configuration
  nodes                = [local.talos_one.ip]
  endpoints            = [local.talos_one.ip]
}

resource "talos_cluster_kubeconfig" "red_squadron_talos" {
  depends_on           = [talos_machine_bootstrap.red_squadron_talos_one]
  client_configuration = talos_machine_secrets.red_squadron_talos.client_configuration
  node                 = local.talos_one.ip
}

output "talos_client_config" {
  sensitive = true
  value     = data.talos_client_configuration.red_squadron_talos.talos_config
}

output "kubeconfig" {
  sensitive = true
  value     = talos_cluster_kubeconfig.red_squadron_talos.kubeconfig_raw
}

