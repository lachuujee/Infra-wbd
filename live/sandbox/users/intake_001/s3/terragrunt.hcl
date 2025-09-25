dependencies { paths = ["../iam"] }  # order only (no outputs used)

terraform { source = "../../../../../modules/s3" }

locals {
  cfg = read_json(find_in_parent_folders("inputs.json"))
}

inputs = {
  enabled     = try(local.cfg.modules.s3.enabled, false)
  bucket_name = local.cfg.modules.s3.name
  # versioning = try(local.cfg.modules.s3.versioning, true)   # if your module supports
  tags        = try(local.cfg.common_tags, {})
}

