terraform {
  source = "../../../../../modules/iam"
}

locals {
  cfg = read_tfvars_file(find_in_parent_folders("inputs.json"))

  # sanitize sandbox_name -> lower, keep [a-z0-9-]
  name_base = regexreplace(lower(try(local.cfg.sandbox_name, "sandbox")), "[^a-z0-9-]", "-")
  role_base = "${local.name_base}-iam"
}

inputs = {
  region               = try(local.cfg.aws_region, "us-east-1")

  # set both the module display name and the actual IAM role name from sandbox_name
  name                 = local.role_base
  role_name            = local.role_base

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
