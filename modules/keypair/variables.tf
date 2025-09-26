# Align with provider.tf: declare region
variable "region" {
  type        = string
  description = "AWS region for this module's provider"
}

variable "sandbox_name" {
  type = string
}

variable "enabled" {
  type    = bool
  default = false
}

# Optional override; if set, it wins over "<sandbox_name>-keypair"
variable "key_name_override" {
  type    = string
  default = null
}

# Crypto
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

# Extra tags merged into all resources (e.g., RequestID, Requester, Environment)
variable "tags_extra" {
  type    = map(string)
  default = {}
}

locals {
  # Final KeyPair (and Secret) name: "<sandbox_name>-keypair" unless overridden
  name_base = trimspace(var.sandbox_name)
  key_name  = coalesce(var.key_name_override, "${name_base}-keypair")

  common_tags = merge(
    {
      Name = key_name
    },
    var.tags_extra
  )
}
