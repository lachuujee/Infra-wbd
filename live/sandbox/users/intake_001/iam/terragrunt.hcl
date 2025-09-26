# live/sandbox/users/intake_001/iam/terragrunt.hcl
terraform {
  source = "../../../../../modules/iam"
}

locals {
  # Locate and read inputs.json safely (single-line ternary fixes the parse error)
  inputs_path = find_in_parent_folders("inputs.json", "NOT_FOUND")
  cfg = (local.inputs_path != "NOT_FOUND" && fileexists(local.inputs_path)) ? read_tfvars_file(local.inputs_path) : {}

  # Derive role name from sandbox_name (spaces -> underscores; keep case/_)
  raw_name  = try(local.cfg.sandbox_name,
             try(local.cfg["sandbox_name"],
             try(local.cfg, "sandbox")))
  name_base = replace(trimspace(local.raw_name), " ", "_")
  role_base = "${local.name_base}_iam"
}

inputs = {
  region               = try(local.cfg.aws_region, "us-east-1")
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
