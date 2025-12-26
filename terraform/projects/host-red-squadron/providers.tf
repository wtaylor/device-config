terraform {
  required_version = ">= 1.11.1"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.89.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "5.6.0"
    }
  }
}

provider "vault" {}

provider "proxmox" {
  endpoint = "https://red-one.willtaylor.info:8006"
  insecure = true

  ssh {
    agent = true
  }
}
