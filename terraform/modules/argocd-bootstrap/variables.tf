variable "bootstrap_mode" {
  type = string
  validation {
    condition     = contains(["system", "full"], var.bootstrap_mode)
    error_message = "The bootstrap_mode must be either 'system' for bootstrapping minimal system applications or 'full' for deploying the full root tree"
  }
}

