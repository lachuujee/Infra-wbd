variable "enabled" {
  type    = bool
  default = true
}

variable "region" {
  type        = string
  description = "AWS region for this module's provider"
  default     = "us-east-1"
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

# Default to CIDR mode; IPAM only if ipam_pool_id is set to non-empty
variable "cidr_block" {
  type        = string
  description = "VPC CIDR (used unless ipam_pool_id is provided)"
  default     = "10.0.0.0/16"
}

variable "ipam_pool_id" {
  type        = string
  description = "IPAM pool id (if non-empty, module uses IPAM)"
  default     = ""
}

variable "vpc_netmask_length" {
  type        = number
  description = "VPC netmask length for IPAM mode"
  default     = 16
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
