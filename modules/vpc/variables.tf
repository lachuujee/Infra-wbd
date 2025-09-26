variable "region" {
  type        = string
  description = "AWS region for this module's provider"
}

variable "enabled" {
  type    = bool
  default = true
}

# Used for naming (e.g., sbx_intake_id_001)
variable "sandbox_name" {
  type = string
}

# Optional override for Name prefix; if null we use sandbox_name
variable "name_prefix_override" {
  type    = string
  default = null
}

# --- Addressing ---
# Default to classic CIDR so we don't depend on IPAM by default.
variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

# If you later want IPAM, set cidr_block=null and provide these:
variable "ipam_pool_id" {
  type    = string
  default = null
}
variable "vpc_netmask_length" {
  type    = number
  default = 16
}

# Optional AZs (e.g., ["us-east-1a","us-east-1b"]); if null, module auto-picks 2
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

# ---------- Common locals for naming/tags ----------
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
