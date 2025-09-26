# live/sandbox/users/intake_001/s3/terragrunt.hcl
terraform {
  source = "../../../../../modules/s3"
}

locals {
  inputs_path = "${get_terragrunt_dir()}/../inputs.json"
  cfg         = jsondecode(file(local.inputs_path))
}

inputs = {
  # REQUIRED by your module (variables.tf: variable "region")
  region     = try(local.cfg.aws_region, "us-east-1")

  enabled    = local.cfg.modules.s3.enabled
  request_id = local.cfg.request_id

  # Keep JSON name exactly; force bucket name to that value
  name                 = local.cfg.modules.s3.name
  bucket_name_override = local.cfg.modules.s3.name

  # Optional controls
  versioning    = try(local.cfg.modules.s3.versioning, true)
  block_public  = try(local.cfg.modules.s3.block_public, true)
  force_destroy = try(local.cfg.modules.s3.force_destroy, false)
  kms_key_id    = try(local.cfg.modules.s3.kms_key_id, null)

  tags_extra = {
    RequestID   = local.cfg.request_id
    Requester   = local.cfg.requester
    Environment = local.cfg.environment
    Service     = "S3"
  }
}
