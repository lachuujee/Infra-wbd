# Region passed from Terragrunt
variable "region" {
  type        = string
  description = "AWS region for this module"
}

# Enable/disable creation
variable "enabled" {
  type    = bool
  default = false
}

# Source for final key name "<sandbox_name>-keypair"
variable "sandbox_name" {
  type = string
}

# Optional explicit override for the key name
variable "key_name_override" {
  type    = string
  default = null
}

# Crypto settings
variable "algorithm" {
  type    = string
  default = "RSA" # or "ED25519"
  validation {
    condition     = contains(["RSA", "ED25519"], var.algorithm)
    error_message = "algorithm must be RSA or ED25519."
  }
}

variable "rsa_bits" {
  type    = number
  default = 4096
}

# Extra tags applied to all resources
variable "tags_extra" {
  type    = map(string)
  default = {}
}

locals {
  # Final names
  name_base = var.sandbox_name
  key_name  = coalesce(var.key_name_override, "${local.name_base}-keypair")

  common_tags = merge(
    { Name = local.key_name },
    var.tags_extra
  )
}
