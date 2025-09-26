terraform {
  source = "../../../../../modules/iam"
}

locals {
  # Detect inputs.json once
  inputs_path = find_in_parent_folders("inputs.json", "NOT_FOUND")
  has_file    = local.inputs_path != "NOT_FOUND" && fileexists(local.inputs_path)

  # Helper to read the file repeatedly (Terragrunt allows this)
  # NOTE: We *only* call read_tfvars_file() when has_file=true
  # so condition branches always return the same type.
  sandbox_raw = local.has_file
    ? try(
        # If it's a map: take .sandbox_name
        read_tfvars_file(local.inputs_path).sandbox_name,
        # If it's a bare string: use that string
        read_tfvars_file(local.inputs_path)
      )
    : "sandbox"

  # Clean for IAM: keep case/underscores, just convert spaces -> underscores
  name_base = replace(trimspace(local.sandbox_raw), " ", "_")
  role_base = "${local.name_base}_iam"

  # Region (string)
  region_val = local.has_file
    ? try(read_tfvars_file(local.inputs_path).aws_region, "us-east-1")
    : "us-east-1"

  # Assume services (list(string))
  assume_services_val = local.has_file
    ? try(read_tfvars_file(local.inputs_path).modules.iam.assume_services, ["ec2.amazonaws.com"])
    : ["ec2.amazonaws.com"]

  # Managed policies (list(string))
  managed_policies_val = local.has_file
    ? try(read_tfvars_file(local.inputs_path).modules.iam.managed_policy_arns, ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"])
    : ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  # IAM path (string)
  path_val = local.has_file
    ? try(read_tfvars_file(local.inputs_path).modules.iam.path, "/")
    : "/"

  # Tags support (map(string))
  common_tags_val = local.has_file
    ? try(read_tfvars_file(local.inputs_path).common_tags, {})
    : {}

  # Tag fields (strings)
  request_id_val = local.has_file
    ? try(read_tfvars_file(local.inputs_path).request_id, "unknown")
    : "unknown"

  requester_val = local.has_file
    ? try(read_tfvars_file(local.inputs_path).requester, "unknown")
    : "unknown"

  environment_val = local.has_file
    ? try(read_tfvars_file(local.inputs_path).environment, "sandbox")
    : "sandbox"
}

inputs = {
  # Provider region into the module
  region     = local.region_val

  # Role identity (overrides module defaults)
  name       = local.role_base
  role_name  = local.role_base

  # Trust & permissions
  assume_services      = local.assume_services_val
  managed_policy_arns  = local.managed_policies_val

  path = local.path_val

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
