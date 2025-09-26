terraform {
  source = "../../../../../modules/iam"
}

locals {
  # Find and read inputs.json safely
  inputs_path = find_in_parent_folders("inputs.json", "NOT_FOUND")
  cfg_raw     = (local.inputs_path != "NOT_FOUND" && fileexists(local.inputs_path)) ? read_tfvars_file(local.inputs_path) : {}

  # sandbox_name can be:
  # - cfg_raw.sandbox_name (map)
  # - cfg_raw["sandbox_name"] (map with key lookup)
  # - or cfg_raw itself if the file is just a string
  sandbox_raw = try(local.cfg_raw.sandbox_name, try(local.cfg_raw["sandbox_name"], try(local.cfg_raw, "sandbox")))

  # IAM role name: keep case/underscores, convert spaces to underscores
  name_base = replace(trimspace(local.sandbox_raw), " ", "_")
  role_base = "${local.name_base}_iam"

  # Pull other values safely with fallbacks
  region_val             = try(local.cfg_raw.aws_region, "us-east-1")
  assume_services_val    = try(local.cfg_raw.modules.iam.assume_services, ["ec2.amazonaws.com"])
  managed_policies_val   = try(local.cfg_raw.modules.iam.managed_policy_arns, ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"])
  path_val               = try(local.cfg_raw.modules.iam.path, "/")
  common_tags_val        = try(local.cfg_raw.common_tags, {})
  request_id_val         = try(local.cfg_raw.request_id, "unknown")
  requester_val          = try(local.cfg_raw.requester, "unknown")
  environment_val        = try(local.cfg_raw.environment, "sandbox")
}

inputs = {
  # Provider region for the module
  region     = local.region_val

  # Role identity (overrides module defaults)
  name       = local.role_base
  role_name  = local.role_base

  # Trust & permissions
  assume_services     = local.assume_services_val
  managed_policy_arns = local.managed_policies_val
  path                = local.path_val

  # Tags
  tags_extra = merge(
    local.common_tags_val,
    {
      RequestID   = local.request_id_val
      Requester   = local.requester_val
      Environment = local.environment_val
      Service     = "IAM"
    }
  )
}
