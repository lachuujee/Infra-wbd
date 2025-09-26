terraform {
  source = "../../../../../modules/iam"
}

locals {
  # inputs.json lives one level up from this folder (your screenshot confirms it)
  inputs_path = "${get_terragrunt_dir()}/../inputs.json"
  cfg         = jsondecode(file(local.inputs_path))
}

inputs = {
  region    = "us-east-1"

  # Use the name from your JSON for both the module name and actual IAM role name
  # JSON: modules.iam.name = "sbx_intake_id_001-iam"
  name      = local.cfg.modules.iam.name
  role_name = local.cfg.modules.iam.name

  # Optional gate if your module uses var.enabled
  enabled   = try(local.cfg.modules.iam.enabled, true)

  # Defaults keep EC2/SSM working even if you don’t list policies/trust in JSON
  assume_services      = try(local.cfg.modules.iam.assume_services, ["ec2.amazonaws.com"])
  managed_policy_arns  = try(local.cfg.modules.iam.managed_policy_arns, ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"])
  path                 = try(local.cfg.modules.iam.path, "/")

  tags_extra = {
    RequestID   = local.cfg.request_id
    Requester   = local.cfg.requester
    Environment = local.cfg.environment
    Service     = "IAM"
  }
}
