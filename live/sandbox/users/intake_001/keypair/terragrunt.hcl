dependencies { paths = ["../vpc"] }  # order only (no outputs needed for a plain keypair)

terraform { source = "../../../../../modules/keypair" }

locals {
  cfg = read_json(find_in_parent_folders("inputs.json"))
}

inputs = {
  enabled   = try(local.cfg.modules.keypair.enabled, true)
  key_name  = local.cfg.modules.keypair.name
  # public_key = try(local.cfg.modules.keypair.public_key, null)  # optional import
  tags      = try(local.cfg.common_tags, {})
}

