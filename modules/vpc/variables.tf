variable "region" {
  type        = string
  description = "AWS region for this module's provider"
  default     = "us-east-1"
}

variable "enabled" {
  type    = bool
  default = true
}

# Used for naming, e.g. SBX_INTAKE_ID_001
variable "sandbox_name" {
  type = string
}

variable "name_prefix_override" {
  type    = string
  default = null
}

# Prefer CIDR by default; set cidr_block = null to use IPAM instead
variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

# IPAM settings (used only if cidr_block is null or empty)
variable "ipam_pool_id" {
  type    = string
  default = null
}

variable "vpc_netmask_length" {
  type    = number
  default = 16
}

# Optional AZs (e.g. ["us-east-1a","us-east-1b"]); leave null to auto-pick 2
variable "azs" {
  type    = list(string)
  default = null
}

variable "flow_logs_retention_days" {
  type    = number
  default = 30
}

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
