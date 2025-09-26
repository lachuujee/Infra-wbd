terraform {
  source = "../../../../../modules/s3"
}

locals {
  # Use the supported loader (fixes "unknown function read_json")
  cfg = read_tfvars_file(find_in_parent_folders("inputs.json"))
}

inputs = {
  # Keep region handling same as IAM module
  region               = try(local.cfg.aws_region, "us-east-1")

  enabled              = try(local.cfg.modules.s3.enabled, true)
  name                 = try(local.cfg.modules.s3.name, "s3")
  request_id           = try(local.cfg.request_id, "unknown")

  # Controls
  versioning           = try(local.cfg.modules.s3.versioning, true)
  block_public         = try(local.cfg.modules.s3.block_public, true)
  force_destroy        = try(local.cfg.modules.s3.force_destroy, false)
  kms_key_id           = try(local.cfg.modules.s3.kms_key_id, null)

  # Optional hard override for the actual bucket name
  bucket_name_override = try(local.cfg.modules.s3.bucket_name_override, null)

  tags_extra = merge(
    try(local.cfg.common_tags, {}),
    {
      RequestID   = try(local.cfg.request_id,   "unknown")
      Requester   = try(local.cfg.requester,    "unknown")
      Environment = try(local.cfg.environment,  "sandbox")
      Service     = "S3"
    }
  )
}
