terraform {
  source = "../../../../../modules/iam"
}

locals {
  cfg = read_tfvars_file(find_in_parent_folders("inputs.json"))
terraform {
  source = "../../../../../modules/iam"
}

locals {
  # Find inputs.json safely
  inputs_path = find_in_parent_folders("inputs.json", "NOT_FOUND")
  cfg         = inputs_path != "NOT_FOUND" && fileexists(inputs_path) ? read_tfvars_file(inputs_path) : {}

  # If cfg is a map and has sandbox_name -> use it,
  # else if cfg itself is a string -> use that as the name,
  # else fallback "sandbox".
  raw_name = try(local.cfg.sandbox_name,
             try(local.cfg["sandbox_name"],
             try(local.cfg, "sandbox")))

  # IAM allows underscores/uppercase; replace spaces with underscores only
  name_base = replace(trimspace(local.raw_name), " ", "_")
  role_base = "${local.name_base}_iam"
}

inputs = {
  # Provider region for the module
  region               = try(local.cfg.aws_region, "us-east-1")

  # Role identity (overrides module defaults)
  name                 = local.role_base
  role_name            = local.role_base

  # Trust + permissions (read from inputs.json if provided)
  assume_services      = try(local.cfg.modules.iam.assume_services, ["ec2.amazonaws.com"])
  managed_policy_arns  = try(local.cfg.modules.iam.managed_policy_arns, ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"])

  path                 = try(local.cfg.modules.iam.path, "/")

  # Tags (safe defaults if keys are missing or cfg is not a map)
  tags_extra = merge(
    try(local.cfg.common_tags, {}),
    {
      RequestID   = try(local.cfg.request_id,   "unknown"),
      Requester   = try(local.cfg.requester,    "unknown"),
      Environment = try(local.cfg.environment,  "sandbox"),
      Service     = "IAM",
    }
  )
}
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
