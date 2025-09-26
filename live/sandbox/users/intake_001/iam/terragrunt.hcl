terraform { source = "../../../../../modules/iam" }

locals {
  cfg = read_json(find_in_parent_folders("inputs.json"))
}

inputs = {
  enabled  = try(local.cfg.modules.iam.enabled, true)
  name     = try(local.cfg.modules.iam.name, "iam")
  role_name = try(local.cfg.modules.iam.role_name, "tg-exec-role")

  # Defaults are safe; override by adding to inputs.json if needed
  assume_services      = try(local.cfg.modules.iam.assume_services, ["ec2.amazonaws.com"])
  managed_policy_arns  = try(local.cfg.modules.iam.managed_policy_arns, ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"])
  path                 = try(local.cfg.modules.iam.path, "/")

  # Tags from inputs.json if present; plus standard context
  tags_extra = merge(
    try(local.cfg.common_tags, {}),
    {
      RequestID   = local.cfg.request_id
      Requester   = local.cfg.requester
      Environment = local.cfg.environment
      Service     = "IAM"
    }
  )
}
