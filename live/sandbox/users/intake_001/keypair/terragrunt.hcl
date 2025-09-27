# Keep ordering for run-all (KeyPair after VPC)
dependencies {
  paths = ["../vpc"]
}

terraform {
  source = "../../../../../modules/keypair"
}

locals {
  # inputs.json is one level up from this folder
  inputs_path = "${get_terragrunt_dir()}/../inputs.json"
  cfg         = jsondecode(file(local.inputs_path))
}

inputs = {
  # Region aligned with other modules (fallback to us-east-1)
  region       = try(local.cfg.aws_region, "us-east-1")

  # Enable logic: keypair.enabled, else ec2.enabled, else false
  enabled      = try(local.cfg.modules.keypair.enabled,
                 try(local.cfg.modules.ec2.enabled, false))

  # Used to build "<sandbox_name>-keypair"
  sandbox_name = local.cfg.sandbox_name

  # Tags
  tags_extra = merge(
    try(local.cfg.common_tags, {}),
    {
      RequestID   = local.cfg.request_id
      Requester   = local.cfg.requester
      Environment = local.cfg.environment
      Service     = "KeyPair"
    }
  )
}
