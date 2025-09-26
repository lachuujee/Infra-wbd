# -------- Core ----------
variable "region" {
  type        = string
  description = "AWS region for this module"
  default     = "us-east-1"
}

variable "enabled" {
  type        = bool
  description = "Toggle to create/destroy this stack"
  default     = true
}

variable "sandbox_name" {
  type        = string
  description = "Name used for tagging/prefixing resources (e.g., SBX_INTAKE_ID_001)"
}

variable "name_prefix_override" {
  type        = string
  description = "Optional override for name prefix; defaults to sandbox_name"
  default     = null
}

# -------- Addressing (CIDR default; IPAM only if cidr_block is null) ----------
variable "cidr_block" {
  type        = string
  description = "VPC CIDR. Leave null to use IPAM."
  default     = "10.0.0.0/16"
}

variable "ipam_pool_id" {
  type        = string
  description = "IPAM pool ID (required if cidr_block = null)"
  default     = null
}

variable "vpc_netmask_length" {
  type        = number
  description = "Netmask length used with IPAM (only when cidr_block = null)"
  default     = 16
}

# -------- AZ selection ----------
variable "azs" {
  type        = list(string)
  description = "Optional list of AZs (>=2). If not set or <2, module picks first two in region."
  default     = null
}

# -------- Misc ----------
variable "flow_logs_retention_days" {
  type        = number
  description = "CloudWatch retention for VPC flow logs"
  default     = 30
}

variable "tags_extra" {
  type        = map(string)
  description = "Extra tags merged into all resources"
  default     = {}
}

# -------- Locals derived from inputs ----------
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
