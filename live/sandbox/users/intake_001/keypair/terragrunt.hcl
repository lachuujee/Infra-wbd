# Keep ordering for run-all
dependencies {
  paths = ["../vpc"]
}

terraform {
  source = "../../../../../modules/keypair"
}

locals {
  # Fix: Terragrunt doesn't have read_json; use read_tfvars_file
  cfg = read_tfvars_file(find_in_parent_folders("inputs.json"))
}

inputs = {
  # Align region handling with IAM/S3/EC2
  region        = try(local.cfg.aws_region, "us-east-1")

  # Enable if keypair module is enabled, else follow ec2 enabled as fallback
  enabled       = try(local.cfg.modules.keypair.enabled,
                  try(local.cfg.modules.ec2.enabled, false))

  # Used to name the key/secret: "<sandbox_name>-keypair"
  sandbox_name  = try(local.cfg.sandbox_name, "sandbox")

  # Standard tag fan-out
  tags_extra    = try(local.cfg.common_tags, {})
  # Note: Removed customer/environment here. If you need them later,
  # add variables in the module and wire them where used.
}
