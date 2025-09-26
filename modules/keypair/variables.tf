variable "customer" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

# Optional: if present in inputs.json, use for naming (<sandbox_name>-keypair)
variable "sandbox_name" {
  type    = string
  default = null
}

# Optional override; else we use <sandbox_name>-keypair or <customer>_<environment>-keypair
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

# Extra tags merged into all resources
variable "tags_extra" {
  type    = map(string)
  default = {}
}

locals {
  # Prefer sandbox_name when provided; else fall back to "<customer>_<environment>"
  name_base = (
    var.sandbox_name != null && trimspace(var.sandbox_name) != ""
  ) ? trimspace(var.sandbox_name) : "${var.customer}_${var.environment}"

  # Final KeyPair name
  key_name = coalesce(var.key_name_override, "${local.name_base}-keypair")

  common_tags = merge(
    {
      Name        = local.key_name
      Customer    = var.customer
      Environment = var.environment
    },
    var.tags_extra
  )
}
