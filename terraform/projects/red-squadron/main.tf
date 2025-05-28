locals {
  talos_version = "v1.10.1"

  cluster_vip  = "172.28.2.10"
  cluster_name = "red-squadron-talos"

  default_gateway = "172.28.0.1"
  dns_servers     = ["172.28.0.1"]

  pci_pass_intel_igpu = {
    name  = "intel-igpu"
    label = "net.tk831.dev/intel-igpu-enabled"
  }
  pci_pass_coral = {
    name  = "coral-pcie"
    label = "net.tk831.dev/coral-pci-enabled"
  }

  host_cluster_name = "red-squadron"
  host_nodes = {
    "red-one" = {}
  }

  talos_nodes = {
    "red-one-talos" = {
      host_node_name = "red-one"
      vm_id          = 101
      node_ip        = "172.28.2.11"
      bootstrap      = true
      role           = "controlplane"
      cpu            = 8
      memory         = 32768
      disk           = 256
      pci_passes     = [local.pci_pass_intel_igpu, local.pci_pass_coral]
    },
    "red-one-talos-worker-one" = {
      host_node_name = "red-one"
      vm_id          = 102
      node_ip        = "172.28.2.15"
      bootstrap      = false
      role           = "worker"
      cpu            = 8
      memory         = 8192
      disk           = 256
      pci_passes     = []
    },
    "red-one-talos-worker-two" = {
      host_node_name = "red-one"
      vm_id          = 103
      node_ip        = "172.28.2.16"
      bootstrap      = false
      role           = "worker"
      cpu            = 8
      memory         = 8192
      disk           = 256
      pci_passes     = []
    }
  }

  deploy_bootstrap_manifests = false
}

data "talos_image_factory_extensions_versions" "red_squadron" {
  talos_version = local.talos_version
  filters = {
    names = [
      "gasket-driver",
      "i915",
      "intel-ice-firmware",
      "intel-ucode",
      "iscsi-tools",
      "mei",
      "qemu-guest-agent",
      "thunderbolt",
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
  for_each     = local.host_nodes
  content_type = "iso"
  datastore_id = "local"
  node_name    = each.key
  file_name    = "talos-nocloud-amd64.iso"

  url = data.talos_image_factory_urls.red_squadron.urls.iso
}

resource "proxmox_virtual_environment_hardware_mapping_pci" "red_squadron_igpu" {
  comment = "Mapping for Intel integrated GPU"
  name    = local.pci_pass_intel_igpu.name
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
  name    = local.pci_pass_coral.name
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

resource "talos_machine_secrets" "red_squadron_talos" {}

data "talos_client_configuration" "red_squadron_talos" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.red_squadron_talos.client_configuration
  nodes                = [local.talos_nodes["red-one-talos"].node_ip]
  endpoints            = [local.talos_nodes["red-one-talos"].node_ip]
}

module "talos_nodes" {
  source   = "../../modules/talos-node"
  for_each = local.talos_nodes

  vm_host_cluster_name = local.host_cluster_name
  vm_host_node_name    = each.value.host_node_name
  vm_id                = each.value.vm_id
  node_name            = each.key
  vm_tags              = [each.value.role, "kubernetes", "talos", "terraform"]
  vm_cpu_cores         = each.value.cpu
  vm_memory            = each.value.memory
  vm_root_disk_size    = each.value.disk

  vm_installer_cdrom_file_id = proxmox_virtual_environment_download_file.talos_iso[each.value.host_node_name].id

  vm_host_pci_mapping_names          = each.value.pci_passes
  node_talos_oci_installer_image_url = data.talos_image_factory_urls.red_squadron.urls.installer

  node_ip              = each.value.node_ip
  node_default_gateway = local.default_gateway
  node_dns_servers     = local.dns_servers

  node_labels = { for p in each.value.pci_passes : p.label => "true" }

  node_deploy_bootstrap_manifests         = each.value.bootstrap && local.deploy_bootstrap_manifests
  node_talos_secrets_machine_secrets      = talos_machine_secrets.red_squadron_talos.machine_secrets
  node_talos_secrets_client_configuration = talos_machine_secrets.red_squadron_talos.client_configuration
  node_role                               = each.value.role
  node_enable_scheduling_on_controlplanes = true

  cluster_name = local.cluster_name
  cluster_vip  = local.cluster_vip

  node_execute_talos_bootstrap = each.value.bootstrap
}

resource "talos_cluster_kubeconfig" "red_squadron_talos" {
  depends_on           = [module.talos_nodes["red-one-talos"]]
  client_configuration = talos_machine_secrets.red_squadron_talos.client_configuration
  node                 = local.talos_nodes["red-one-talos"].node_ip
}

module "vault_auth" {
  source     = "../../modules/k8s-vault-auth"
  depends_on = [module.talos_nodes["red-one-talos"]]

  create_namespace                  = true
  namespace                         = "external-secrets"
  service_account_name              = "eso-vault-css"
  service_account_token_secret_name = "external-secrets-vault-token"
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "red_squadron" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.host
  kubernetes_ca_cert     = base64decode(talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.ca_certificate)
  disable_local_ca_jwt   = true
  disable_iss_validation = true
  issuer                 = talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.host
}

resource "vault_kubernetes_auth_backend_role" "red_squadron" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "external-secrets-css"
  bound_service_account_names      = ["eso-vault-css"]
  bound_service_account_namespaces = ["external-secrets"]
  token_ttl                        = 3600
  token_policies                   = ["kubernetes-external-secrets"]
  alias_name_source                = "serviceaccount_name"
}

module "proxmox_csi_user" {
  source = "../../modules/proxmox-csi-user"

  create_csi_role      = true
  proxmox_csi_username = "red-squadron-talos-csi"
}

resource "vault_kv_secret_v2" "csi_credentials" {
  mount = "kv"
  name  = "services/csi-proxmox/proxmox-credentials"
  data_json = jsonencode(
    {
      api_token_id = module.proxmox_csi_user.api_token_id
      api_token    = module.proxmox_csi_user.api_token
    }
  )
}

module "argocd-bootstrap" {
  source         = "../../modules/argocd-bootstrap"
  bootstrap_mode = "system"

  depends_on = [
    module.talos_nodes["red-one-talos"],
    vault_kv_secret_v2.csi_credentials
  ]
}
