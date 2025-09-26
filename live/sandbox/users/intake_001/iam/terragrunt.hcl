terraform {
  source = "../../../../../modules/iam"
}

locals {
  # 1) Locate inputs.json safely
  inputs_path = find_in_parent_folders("inputs.json", "NOT_FOUND")

  # 2) Read it if found, else fall back to an empty map
  cfg = (local.inputs_path != "NOT_FOUND" && fileexists(local.inputs_path))
       ? read_tfvars_file(local.inputs_path)
       : {}

  # 3) Pull sandbox_name (or fall back)
  raw_name  = try(local.cfg.sandbox_name, "sandbox")

  # 4) IAM name: keep UPPERCASE and underscores, just replace spaces with underscores
  name_base = replace(trimspace(local.raw_name), " ", "_")

  # 5) Final role name: <sandbox_name>_iam   (change to "-iam" if you prefer)
  role_base = "${local.name_base}_iam"
}

inputs = {
  region               = try(local.cfg.aws_region, "us-east-1")

  # Use our computed name for both display/tagging and the actual IAM role name
  name                 = local.role_base
  role_name            = local.role_base

  # Trust & permissions (from inputs.json if present)
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
