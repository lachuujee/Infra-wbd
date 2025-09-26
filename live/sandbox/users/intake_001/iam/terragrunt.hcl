terraform {
  source = "../../../../../modules/iam"
}

locals {
  # Simple fix: read inputs.json (tfvars JSON) from a parent
  cfg = read_tfvars_file(find_in_parent_folders("inputs.json"))
}

inputs = {
  # >>> IMPORTANT: pass region into the module <<<
  region               = try(local.cfg.aws_region, "us-east-1")

  enabled              = try(local.cfg.modules.iam.enabled, true)
  name                 = try(local.cfg.modules.iam.name, "iam")
  role_name            = try(local.cfg.modules.iam.role_name, "tg-exec-role")
  assume_services      = try(local.cfg.modules.iam.assume_services, ["ec2.amazonaws.com"])
  managed_policy_arns  = try(local.cfg.modules.iam.managed_policy_arns, ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"])
  path                 = try(local.cfg.modules.iam.path, "/")

  tags_extra = merge(
    try(local.cfg.common_tags, {}),
    {
      RequestID   = try(local.cfg.request_id,   "unknown")
      Requester   = try(local.cfg.requester,    "unknown")
      Environment = try(local.cfg.environment,  "sandbox")
      Service     = "IAM"
    }
  )
}
