terraform {
  source = "../../../../../modules/vpc"
}

locals {
  inputs_path = "${get_terragrunt_dir()}/../inputs.json"
  cfg         = jsondecode(file(local.inputs_path))
}

inputs = {
  # naming
  sandbox_name = local.cfg.sandbox_name

  # addressing (pick one or none)
  ipam_pool_id           = try(local.cfg.modules.vpc.ipam_pool_id, null)
  vpc_netmask_length     = try(local.cfg.modules.vpc.vpc_netmask_length, 16)
  cidr_block             = try(local.cfg.modules.vpc.cidr_block, null)

  # optional azs override (else module picks first two in region)
  azs                    = try(local.cfg.modules.vpc.azs, null)

  flow_logs_retention_days = try(local.cfg.modules.vpc.flow_logs_retention_days, 30)

  tags_extra = merge(
    try(local.cfg.common_tags, {}),
    {
      RequestID   = local.cfg.request_id
      Requester   = local.cfg.requester
      Environment = local.cfg.environment
      Service     = "VPC"
    }
  )
}

