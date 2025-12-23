terraform {
  required_version = ">= 1.11.1"
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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "5.6.0"
    }
  }
}

provider "kubernetes" {
  host                   = talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.host
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.ca_certificate)
  client_certificate     = base64decode(talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.client_key)
}

provider "kubectl" {
  host                   = talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.host
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.ca_certificate)
  client_certificate     = base64decode(talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.red_squadron_talos.kubernetes_client_configuration.client_key)
}

provider "proxmox" {
  endpoint = "https://tardis.willtaylor.info:8006"
  insecure = true

  ssh {
    agent = true
  }
}
