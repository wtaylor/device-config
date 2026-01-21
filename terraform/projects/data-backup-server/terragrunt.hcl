include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  before_hook "before_hook" {
    commands = ["init", "plan", "apply", "import"]
    execute = ["./scripts/generate-ignition.sh"]
  }

  extra_arguments "extra_vars" {
    commands = ["init", "plan", "apply", "import", "destroy"]
    env_vars = {
      PROXMOX_VE_USERNAME = "${run_cmd("--terragrunt-quiet", "../../../scripts/vault_get_secret.sh", "system/device-config/tardis-proxmox-credentials", "username")}"
      PROXMOX_VE_PASSWORD = "${run_cmd("--terragrunt-quiet", "../../../scripts/vault_get_secret.sh", "system/device-config/tardis-proxmox-credentials", "password")}"
      PROXMOX_VE_SSH_USERNAME = "${run_cmd("--terragrunt-quiet", "../../../scripts/vault_get_secret.sh", "system/device-config/tardis-proxmox-credentials", "sshUsername")}"
    }
  }
}

