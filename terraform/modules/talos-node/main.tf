locals {
  datastore_id = "local-zfs"
}

resource "proxmox_virtual_environment_vm" "node_vm" {
  name = var.node_name
  tags = var.vm_tags

  node_name = var.vm_host_node_name
  vm_id     = var.vm_id

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  boot_order = ["scsi0", "ide0", "net0"]

  agent {
    enabled = true
  }

  cpu {
    cores = var.vm_cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.vm_memory
    floating  = var.vm_memory
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

  dynamic "hostpci" {
    for_each = toset(var.vm_host_pci_mapping_names)

    content {
      device  = "hostpci${index(var.vm_host_pci_mapping_names, each.value)}"
      mapping = each.value
      pcie    = true
    }
  }

  disk {
    datastore_id = local.datastore_id
    interface    = "scsi0"
    size         = 256
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

data "talos_machine_configuration" "node_mc" {
  cluster_name     = var.cluster_name
  machine_type     = var.node_role
  cluster_endpoint = "https://${var.cluster_vip}:6443"
  machine_secrets  = var.node_talos_secrets_machine_secrets
}

resource "talos_machine_configuration_apply" "node_mc" {
  depends_on = [proxmox_virtual_environment_vm.node_vm]

  client_configuration        = var.node_talos_secrets_client_configuration
  machine_configuration_input = data.talos_machine_configuration.node_mc.machine_configuration
  node                        = var.node_ip
  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = var.node_talos_oci_installer_image_url
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
            addresses = ["${var.node_ip}/22"]
            vip = {
              ip = var.cluster_vip
            }
            routes = [{
              network = "0.0.0.0/0"
              gateway = var.node_default_gateway
            }]
          }]
        }
        nodeLabels = merge({
          "topology.kubernetes.io/region" = var.vm_host_cluster_name
          "topology.kubernetes.io/zone"   = var.vm_host_node_name
          "node.kubernetes.io/exclude-from-external-load-balancers" = {
            "$patch" = "delete"
          }
        }, var.node_labels)
        features = {
          hostDNS = {
            forwardKubeDNSToHost = false
          }
        }
        logging = {
          destinations = [{
            endpoint = "udp://vector-server.willtaylor.info:6051/"
            format   = "json_lines"
          }]
        }
      }
      cluster = {
        allowSchedulingOnControlPlanes = var.node_enable_scheduling_on_controlplanes
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
        extraManifests = var.node_deploy_bootstrap_manifests ? [
          "https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/refs/tags/v0.9.1/deploy/standalone-install.yaml",
          "https://raw.githubusercontent.com/wtaylor/device-config/refs/heads/main/kubernetes/bootstrap-utils/red-squadron-talos-argocd-rendered.yaml"
        ] : []
        inlineManifests = var.node_deploy_bootstrap_manifests ? [
          {
            name     = "cilium-install-job"
            contents = file("${path.module}/files/cilium-install-job.yaml")
          },
          {
            name     = "argocd-namespace"
            contents = <<EOF
            apiVersion: v1
            kind: Namespace
            metadata:
              name: argocd
            EOF
          }
        ] : []
      }
    })
  ]
}

resource "talos_machine_bootstrap" "cluster_bootstrap" {
  count = var.node_execute_talos_bootstrap ? 1 : 0
  depends_on = [
    talos_machine_configuration_apply.node_mc
  ]
  node                 = var.node_ip
  client_configuration = var.node_talos_secrets_client_configuration
}

resource "time_sleep" "wait_cluster_bootstrap" {
  count = var.node_execute_talos_bootstrap ? 1 : 0
  depends_on = [
    talos_machine_bootstrap.cluster_bootstrap
  ]
  create_duration = "60s"
}

