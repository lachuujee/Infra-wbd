terraform { source = "../../../../../modules/s3" }

locals {
  cfg = read_json(find_in_parent_folders("inputs.json"))
}

inputs = {
  enabled       = try(local.cfg.modules.s3.enabled, true)
  name          = try(local.cfg.modules.s3.name, "s3")
  request_id    = local.cfg.request_id

  # Controls (optional in JSON)
  versioning    = try(local.cfg.modules.s3.versioning, true)
  block_public  = try(local.cfg.modules.s3.block_public, true)
  force_destroy = try(local.cfg.modules.s3.force_destroy, false)
  kms_key_id    = try(local.cfg.modules.s3.kms_key_id, null)

  # If you ever need to hard-override the bucket name:
  bucket_name_override = try(local.cfg.modules.s3.bucket_name_override, null)

  tags_extra = merge(
    try(local.cfg.common_tags, {}),
    {
      RequestID   = local.cfg.request_id
      Requester   = local.cfg.requester
      Environment = local.cfg.environment
      Service     = "S3"
    }
  )
}
