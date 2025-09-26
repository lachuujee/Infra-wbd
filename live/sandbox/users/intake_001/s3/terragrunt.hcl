terraform {
  source = "../../../../../modules/s3"
}

locals {
  cfg = read_tfvars_file(find_in_parent_folders("inputs.json"))

  # sanitise just like we did elsewhere (used by the module anyway)
  name_clean = regexreplace(lower(try(local.cfg.modules.s3.name, "s3")), "[^a-z0-9-]", "-")
}

inputs = {
  region               = try(local.cfg.aws_region, "us-east-1")

  # force it (no "unknown" fallback) so bad names don't slip through
  request_id           = local.cfg.request_id

  enabled              = try(local.cfg.modules.s3.enabled, true)
  name                 = local.name_clean
  versioning           = try(local.cfg.modules.s3.versioning, true)
  block_public         = try(local.cfg.modules.s3.block_public, true)
  force_destroy        = try(local.cfg.modules.s3.force_destroy, false)
  kms_key_id           = try(local.cfg.modules.s3.kms_key_id, null)
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
