terraform {
  required_providers {
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
}

