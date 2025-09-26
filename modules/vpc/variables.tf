variable "region" {
  type        = string
  description = "AWS region for this module's provider"
}

variable "enabled" {
  type    = bool
  default = true
}

variable "sandbox_name" {
  type = string
}

variable "name_prefix_override" {
  type    = string
  default = null
}

# Default to classic CIDR to avoid IPAM dependency unless you explicitly set cidr_block = null
variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

# For IPAM mode, set cidr_block = null and provide both below
variable "ipam_pool_id" {
  type    = string
  default = null
}

variable "vpc_netmask_length" {
  type    = number
  default = 16
}

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
