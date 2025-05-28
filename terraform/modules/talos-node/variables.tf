variable "vm_host_node_name" {
  type = string
}

variable "vm_host_cluster_name" {
  type = string
}

variable "vm_tags" {
  type = list(string)
}

variable "vm_id" {
  type = number
}

variable "vm_cpu_cores" {
  type = number
}

variable "vm_memory" {
  type = number
}

variable "vm_installer_cdrom_file_id" {
  type = string
}

variable "node_talos_oci_installer_image_url" {
  type = string
}

variable "vm_host_pci_mapping_names" {
  type = list(string)
}

variable "vm_root_disk_size" {
  type = number
}

variable "cluster_name" {
  type = string
}

variable "cluster_vip" {
  type = string
}

variable "node_name" {
  type = string
}

variable "node_ip" {
  type = string
}

variable "node_default_gateway" {
  type = string
}

variable "node_dns_servers" {
  type = list(string)
}

variable "node_deploy_bootstrap_manifests" {
  type = bool
}

variable "node_talos_secrets_machine_secrets" {
  type = object({
    certs      = any
    cluster    = any
    secrets    = any
    trustdinfo = any
  })
}

variable "node_talos_secrets_client_configuration" {
  type = object({
    ca_certificate     = string
    client_certificate = string
    client_key         = string
    host               = string
  })
}

variable "node_role" {
  type = string
}

variable "node_enable_scheduling_on_controlplanes" {
  type = bool
}

variable "node_labels" {
  type = map(string)
}

variable "node_execute_talos_bootstrap" {
  type = bool
}
