terraform {
  extra_arguments "common_vars" {
    commands = ["init", "plan", "apply", "import", "destroy", "state"]
    env_vars = {
      AWS_REQUEST_CHECKSUM_CALCULATION = "when_required"
      AWS_RESPONSE_CHECKSUM_VALIDATION = "when_required"
      AWS_ACCESS_KEY_ID = "${run_cmd("--terragrunt-quiet", "../../../scripts/vault_get_secret.sh", "system/device-config/terraform-backend-credentials", "keyID")}"
      AWS_SECRET_ACCESS_KEY = "${run_cmd("--terragrunt-quiet", "../../../scripts/vault_get_secret.sh", "system/device-config/terraform-backend-credentials", "applicationKey")}"
      PROXMOX_VE_USERNAME = "${run_cmd("--terragrunt-quiet", "../../../scripts/vault_get_secret.sh", "system/device-config/terraform-backend-credentials", "keyID")}"
      PROXMOX_VE_PASSWORD = "${run_cmd("--terragrunt-quiet", "../../../scripts/vault_get_secret.sh", "system/device-config/terraform-backend-credentials", "keyID")}"
      PROXMOX_VE_SSH_USERNAME = "${run_cmd("--terragrunt-quiet", "../../../scripts/vault_get_secret.sh", "system/device-config/terraform-backend-credentials", "keyID")}"
      VAULT_ADDR = "https://vault.willtaylor.info"
    }
  }
}

generate "backend" {
  path      = "tg_backend.tf"

  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://s3.eu-central-003.backblazeb2.com"
    }
    region = "main"
    bucket = "0NIwoqKe3wi8z9fm0RrN5bm5L7tfstate"
    key    = "terraform/device-config/${path_relative_to_include()}/terraform.tfstate"

    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
    skip_s3_checksum            = true
  }
}
EOF
}
