terraform {
  source = "../../../../../modules/vpc"
}

locals {
  inputs_path = "${get_terragrunt_dir()}/../inputs.json"
  cfg         = jsondecode(file(local.inputs_path))
}

inputs = {
  # keep explicit & simple
  region       = try(local.cfg.aws_region, "us-east-1")
  enabled      = try(local.cfg.modules.vpc.enabled, true)

  # naming input
  sandbox_name = local.cfg.sandbox_name

  # if your JSON provides cidr_block or azs, pass them; else module will use defaults
  cidr_block   = try(local.cfg.modules.vpc.cidr_block, null)
  azs          = try(local.cfg.modules.vpc.azs, null)

  flow_logs_retention_days = try(local.cfg.modules.vpc.flow_logs_retention_days, 30)

  tags_extra = {
    RequestID   = local.cfg.request_id
    Requester   = local.cfg.requester
    Environment = local.cfg.environment
    Service     = "VPC"
  }
}
