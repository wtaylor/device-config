terraform {
  before_hook "generate_ignition" {
    commands = ["init", "plan", "apply", "import"]
    execute = ["./scripts/generate-ignition.sh"]
  }

  after_hook "unmount_roots" {
    commands = ["init", "plan", "apply", "import", "destroy", "state"]
    execute = ["../../../scripts/unmount_roots.sh"]
  }

  error_hook "unmount_roots" {
    commands = ["init", "plan", "apply", "import", "destroy", "state"]
    execute = ["../../../scripts/unmount_roots.sh"]
    on_errors = [
      ".*",
    ]
  }

  extra_arguments "extra_vars" {
    commands = ["init", "plan", "apply", "import", "destroy", "state"]
    env_vars = {
      AWS_REQUEST_CHECKSUM_CALCULATION = "when_required"
      AWS_RESPONSE_CHECKSUM_VALIDATION = "when_required"
      AWS_ACCESS_KEY_ID = "${run_cmd("--terragrunt-quiet", "../../../scripts/roots_get_secret.sh", "tf_backend_s3_access_key")}"
      AWS_SECRET_ACCESS_KEY = "${run_cmd("--terragrunt-quiet", "../../../scripts/roots_get_secret.sh", "tf_backend_s3_secret_key")}"
      PROXMOX_VE_USERNAME = "${run_cmd("--terragrunt-quiet", "../../../scripts/roots_get_secret.sh", "proxmox_username")}"
      PROXMOX_VE_PASSWORD = "${run_cmd("--terragrunt-quiet", "../../../scripts/roots_get_secret.sh", "proxmox_password")}"
      PROXMOX_VE_SSH_USERNAME = "${run_cmd("--terragrunt-quiet", "../../../scripts/roots_get_secret.sh", "proxmox_ssh_username")}"
      TF_VAR_state_encryption_passphrase = "${run_cmd("--terragrunt-quiet", "../../../scripts/roots_get_secret.sh", "tfstate_encryption_passphrase")}"
    }
  }
}

