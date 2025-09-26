terraform {
  source = "../../../../../modules/vpc"
}

locals {
  inputs_path = "${get_terragrunt_dir()}/../inputs.json"
  cfg         = jsondecode(file(local.inputs_path))
}

inputs = {
  region       = try(local.cfg.aws_region, "us-east-1")
  enabled      = try(local.cfg.modules.vpc.enabled, true)
  sandbox_name = local.cfg.sandbox_name

  cidr_block   = try(local.cfg.modules.vpc.cidr_block, null)  # null => use default in module
  azs          = try(local.cfg.modules.vpc.azs, null)         # null => module picks first 2 AZs

  flow_logs_retention_days = try(local.cfg.modules.vpc.flow_logs_retention_days, 30)

  tags_extra = {
    RequestID   = local.cfg.request_id
    Requester   = local.cfg.requester
    Environment = local.cfg.environment
    Service     = "VPC"
  }
}
