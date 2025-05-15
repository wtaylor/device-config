terraform {
  required_version = ">= 1.11.4"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.77.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.8.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "4.8.0"
    }
  }
  backend "s3" {
    endpoints = {
      s3 = "https://s3.eu-central-003.backblazeb2.com"
    }
    region = "main"
    bucket = "0NIwoqKe3wi8z9fm0RrN5bm5L7tfstate"
    key    = "terraform/device-config/red-squadron/terraform.tfstate"

    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
    skip_s3_checksum            = true
  }
}

provider "proxmox" {
  endpoint = "https://red-one.willtaylor.info:8006"
  insecure = true

  ssh {
    agent = true
  }
}

provider "kubernetes" {
  host                   = talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.host
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.ca_certificate)
  client_certificate     = base64decode(talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.client_key)
}

