terraform {
  source = "../../../../../modules/iam"
}

locals {
  inputs_path = "${get_terragrunt_dir()}/../inputs.json"
  cfg         = read_tfvars_file(local.inputs_path)
}

inputs = {
  region    = "us-east-1"

  # Use the name from your JSON as both module name and actual IAM role name
  name      = local.cfg.modules.iam.name          # "sbx_intake_id_001-iam"
  role_name = local.cfg.modules.iam.name

  # Trust & permissions (defaults if not present)
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
