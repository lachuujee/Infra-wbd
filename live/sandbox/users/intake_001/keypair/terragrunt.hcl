dependencies { paths = ["../vpc"] }

terraform { source = "../../../../../modules/keypair" }

locals {
  cfg = read_json(find_in_parent_folders("inputs.json"))
}

inputs = {
  enabled       = try(local.cfg.modules.keypair.enabled,
                  try(local.cfg.modules.ec2.enabled, false))

  sandbox_name  = local.cfg.sandbox_name
  customer      = try(local.cfg.customer, null)
  environment   = local.cfg.environment
  region        = try(local.cfg.region, null)
  tags_extra    = try(local.cfg.common_tags, {})
}
