terraform {
  source = "../../../../../modules/vpc"
}

locals {
  inputs_path = "${get_terragrunt_dir()}/../inputs.json"
  cfg         = jsondecode(file(local.inputs_path))
}

inputs = {
  region       = "us-east-1"
  enabled      = try(local.cfg.modules.vpc.enabled, true)
  sandbox_name = local.cfg.sandbox_name

  # Use JSON cidr_block if present; else safe default.
  cidr_block   = try(local.cfg.modules.vpc.cidr_block, "10.0.0.0/16")

  # IPAM optional: if you populate these, module switches to IPAM.
  ipam_pool_id       = try(local.cfg.modules.vpc.ipam_pool_id, "")
  vpc_netmask_length = try(local.cfg.modules.vpc.vpc_netmask_length, 16)

  azs = try(local.cfg.modules.vpc.azs, null)

  flow_logs_retention_days = try(local.cfg.modules.vpc.flow_logs_retention_days, 30)

  tags_extra = {
    RequestID   = local.cfg.request_id
    Requester   = local.cfg.requester
    Environment = local.cfg.environment
    Service     = "VPC"
  }
}
