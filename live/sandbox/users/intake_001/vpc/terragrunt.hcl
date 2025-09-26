dependencies { paths = ["../iam"] }

terraform { source = "../../../../../modules/vpc" }

locals {
  cfg = read_json(find_in_parent_folders("inputs.json"))
}

inputs = {
  enabled        = try(local.cfg.modules.vpc.enabled, true)
  sandbox_name   = local.cfg.sandbox_name

  # If a CIDR is provided in inputs.json, module will use it and ignore IPAM
  cidr_block     = try(local.cfg.modules.vpc.cidr_block, null)

  # Optional AZs (else module chooses first two)
  azs            = try(local.cfg.modules.vpc.azs, null)

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
