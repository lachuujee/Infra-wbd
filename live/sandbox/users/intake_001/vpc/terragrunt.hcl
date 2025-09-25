dependency "iam" { config_path = "../iam" }   # VPC waits for IAM

terraform { source = "../../../../../modules/vpc" }

locals { cfg = read_json(find_in_parent_folders("inputs.json")) }

inputs = {
  enabled    = try(local.cfg.modules.vpc.enabled, true)
  name       = try(local.cfg.modules.vpc.name, "vpc")
  cidr_block = local.cfg.modules.vpc.cidr_block
  az_count   = try(local.cfg.modules.vpc.az_count, 2)
}
