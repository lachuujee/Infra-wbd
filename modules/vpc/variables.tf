# Toggle the whole stack
variable "enabled" {
  type    = bool
  default = true
}

# Used for naming (e.g., SBX_INTAKE_ID_001)
variable "sandbox_name" {
  type = string
}

# Optional override for the name prefix; if null we use sandbox_name
variable "name_prefix_override" {
  type    = string
  default = null
}

# Optional region override (comes from Terragrunt via inputs.json.aws_region).
# If null, providers.tf defaults to us-east-1.
variable "region" {
  type        = string
  description = "Optional AWS region override for this module"
  default     = null
}

# ---- Addressing mode (defaults to CIDR) ----
# Default to classic CIDR. Set to null to switch the module to IPAM mode.
variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

# IPAM inputs (only used when cidr_block = null)
variable "ipam_pool_id" {
  type    = string
  default = null
}

variable "vpc_netmask_length" {
  type    = number
  default = 16
}

# Optional AZs; if null, module auto-picks the first two AZs for the current region
variable "azs" {
  type    = list(string)
  default = null
}

# CloudWatch log retention (days) for VPC Flow Logs
variable "flow_logs_retention_days" {
  type    = number
  default = 30
}

# Extra tags merged into all resources
variable "tags_extra" {
  type    = map(string)
  default = {}
}

# ---------- Locals ----------
locals {
  name_prefix = coalesce(var.name_prefix_override, trimspace(var.sandbox_name))

  common_tags = merge(
    {
      Name    = "${local.name_prefix}-vpc"
      Service = "VPC"
    },
    var.tags_extra
  )
}
