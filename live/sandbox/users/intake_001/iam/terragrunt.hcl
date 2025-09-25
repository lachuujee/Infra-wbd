terraform { source = "../../../../../modules/iam" }

locals {
  cfg = read_json(find_in_parent_folders("inputs.json"))
}

inputs = {
  enabled          = try(local.cfg.modules.iam.enabled, true)
  name             = try(local.cfg.modules.iam.name, "iam")
  create_exec_role = try(local.cfg.modules.iam.create_exec_role, true)
  role_name        = try(local.cfg.modules.iam.role_name, "tg-exec-role")
  tags             = try(local.cfg.common_tags, {})
}

