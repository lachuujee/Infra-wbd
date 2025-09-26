terraform {
  source = "../../../../../modules/s3"
}

locals {
  # inputs.json sits one level up from this folder
  inputs_path = "${get_terragrunt_dir()}/../inputs.json"
  cfg         = jsondecode(file(local.inputs_path))
}

inputs = {
  # Gate from JSON
  enabled    = local.cfg.modules.s3.enabled

  # Required by your module (used for tags and uniqueness when needed)
  request_id = local.cfg.request_id

  # Keep the provided name exactly; force the bucket to that name
  # JSON: modules.s3.name = "sbx-intake-id-001-s3" (already DNS-safe)
  name                 = local.cfg.modules.s3.name
  bucket_name_override = local.cfg.modules.s3.name

  # Optional controls with safe defaults
  versioning    = try(local.cfg.modules.s3.versioning, true)
  block_public  = try(local.cfg.modules.s3.block_public, true)
  force_destroy = try(local.cfg.modules.s3.force_destroy, false)
  kms_key_id    = try(local.cfg.modules.s3.kms_key_id, null)

  # Simple tag fan-out
  tags_extra = {
    RequestID   = local.cfg.request_id
    Requester   = local.cfg.requester
    Environment = local.cfg.environment
    Service     = "S3"
  }
}
