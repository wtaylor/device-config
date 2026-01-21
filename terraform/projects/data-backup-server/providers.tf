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

provider "proxmox" {
  endpoint = "https://tardis.willtaylor.info:8006"
  insecure = true

  ssh {
    agent       = false
    private_key = file("~/.ssh/id_ed25519")
  }
}
