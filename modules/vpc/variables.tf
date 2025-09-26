variable "enabled" {
  type    = bool
  default = true
}

# Used for naming, e.g. SBX_INTAKE_ID_001
variable "sandbox_name" {
  type = string
}

# Optional override for Name prefix; if null we use sandbox_name
variable "name_prefix_override" {
  type    = string
  default = null
}

# --- Addressing options ---
# A) Default to your IPAM pool (fallback when no CIDR is provided)
variable "ipam_pool_id" {
  type    = string
  default = "ipam-pool-03f8473dfbe9f6504"  # <— your pool ID (hard default)
}

variable "vpc_netmask_length" {
  type    = number
  default = 16
}

# B) Classic CIDR (if this is set, module ignores IPAM fields)
variable "cidr_block" {
  type    = string
  default = null
}

# Availability Zones (e.g. ["us-east-1a","us-east-1b"]); if null, module auto-picks 2
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
