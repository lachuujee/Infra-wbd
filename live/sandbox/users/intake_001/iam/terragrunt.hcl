terraform {
  source = "../../../../../modules/iam"
}

locals {
  cfg = read_tfvars_file(find_in_parent_folders("inputs.json"))

  # require sandbox_name from inputs.json; if you prefer a fallback, wrap with try(..., "sandbox")
  raw_name  = local.cfg.sandbox_name

  # IAM role names can include underscores and uppercase; just replace spaces.
  name_base = replace(trimspace(local.raw_name), " ", "_")

  # suffix style: use "_iam"; if you want "-iam" just change the underscore to a hyphen.
  role_base = "${local.name_base}_iam"
}

inputs = {
  region               = try(local.cfg.aws_region, "us-east-1")

  # <- This overrides the module defaults. Result example: SBX_intake_ID_001_iam
  name                 = local.role_base
  role_name            = local.role_base

  # trust and permissions (keep or set via inputs.json)
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
