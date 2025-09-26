# live/sandbox/users/intake_001/iam/terragrunt.hcl
terraform {
  source = "../../../../../modules/iam"
}

locals {
  cfg       = read_tfvars_file(find_in_parent_folders("inputs.json"))
  raw_name  = try(local.cfg.sandbox_name, "sandbox")
  # sanitize without regex: lower + replace spaces/underscores with hyphen
  name_base = lower(replace(replace(trimspace(raw_name), " ", "-"), "_", "-"))
  role_base = "${name_base}-iam"
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
