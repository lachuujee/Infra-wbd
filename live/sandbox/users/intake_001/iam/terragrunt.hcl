terraform {
  source = "../../../../../modules/iam"
}

locals {
  # Find inputs.json safely and read it if present
  inputs_path = find_in_parent_folders("inputs.json", "NOT_FOUND")
  cfg         = inputs_path != "NOT_FOUND" && fileexists(inputs_path) ? read_tfvars_file(inputs_path) : {}

  # Derive sandbox name robustly:
  # 1) If cfg is a map with sandbox_name, use it.
  # 2) If cfg itself is a string, use it.
  # 3) Else fallback.
  raw_name = try(local.cfg.sandbox_name,
             try(local.cfg["sandbox_name"],
             try(local.cfg, "sandbox")))

  # IAM role names can include uppercase and underscores; only convert spaces to underscores.
  name_base = replace(trimspace(local.raw_name), " ", "_")

  # Final role name: <sandbox_name>_iam  (change to "-iam" if you prefer hyphen)
  role_base = "${local.name_base}_iam"
}

inputs = {
  # Provider region into the module
  region               = try(local.cfg.aws_region, "us-east-1")

  # Override module defaults so the actual role is named from sandbox_name
  name                 = local.role_base
  role_name            = local.role_base

  # Trust + permissions (taken from inputs.json if present, else sane defaults)
  assume_services      = try(local.cfg.modules.iam.assume_services, ["ec2.amazonaws.com"])
  managed_policy_arns  = try(local.cfg.modules.iam.managed_policy_arns, ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"])

  path                 = try(local.cfg.modules.iam.path, "/")

  # Tags (safe if keys missing)
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
