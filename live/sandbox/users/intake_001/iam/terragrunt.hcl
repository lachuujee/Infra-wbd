terraform {
  source = "../../../../../modules/iam"
}

locals {
  cfg = read_tfvars_file(find_in_parent_folders("inputs.json"))
}

inputs = {
  # provider region for the module
  region    = "us-east-1"

  # take the role name exactly from JSON (which already follows your sandbox naming)
  name      = local.cfg.modules.iam.name
  role_name = local.cfg.modules.iam.name

  # trust & permissions (use JSON if provided, else sane defaults)
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
