locals {
  inputs_path = "${get_terragrunt_dir()}/../inputs.json"
  cfg         = read_tfvars_file(local.inputs_path)
}

inputs = {
  region    = "us-east-1"

  # Use only the fields that exist in your JSON
  name      = local.cfg.modules.iam.name
  role_name = local.cfg.modules.iam.name

  tags_extra = {
    RequestID   = local.cfg.request_id
    Requester   = local.cfg.requester
    Environment = local.cfg.environment
    Service     = "IAM"
  }
}
