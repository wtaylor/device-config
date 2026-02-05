terraform {
  required_version = ">= 1.11.1"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.89.1"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://s3.eu-central-003.backblazeb2.com"
    }
    region = "main"
    bucket = "0NIwoqKe3wi8z9fm0RrN5bm5L7tfstate"
    key    = "terraform/device-config/openbao-server/terraform.tfstate"

    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
    skip_s3_checksum            = true
  }

  encryption {
    key_provider "pbkdf2" "roots" {
      passphrase  = var.state_encryption_passphrase
      key_length  = 32
      iterations  = 600000
      salt_length = 32
      hash        = "sha512"
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
