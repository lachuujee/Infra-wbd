# Keep ordering for run-all (if you need IAM first)
dependencies {
  paths = ["../iam"]
}

terraform {
  source = "../../../../../modules/vpc"
}

locals {
  # Fix: Terragrunt doesn't have read_json
  cfg = read_tfvars_file(find_in_parent_folders("inputs.json"))
}

inputs = {
  # Align region handling across stacks
  region                   = try(local.cfg.aws_region, "us-east-1")

  enabled                  = try(local.cfg.modules.vpc.enabled, true)
  sandbox_name             = try(local.cfg.sandbox_name, "sandbox")

  # If a CIDR is provided, module uses it and ignores IPAM
  cidr_block               = try(local.cfg.modules.vpc.cidr_block, null)

  # Optional AZs (else module chooses first two)
  azs                      = try(local.cfg.modules.vpc.azs, null)

  flow_logs_retention_days = try(local.cfg.modules.vpc.flow_logs_retention_days, 30)

  tags_extra = merge(
    try(local.cfg.common_tags, {}),
    {
      RequestID   = try(local.cfg.request_id,   "unknown")
      Requester   = try(local.cfg.requester,    "unknown")
      Environment = try(local.cfg.environment,  "sandbox")
      Service     = "VPC"
    }
  )
}
