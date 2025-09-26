dependency "vpc"     { config_path = "../vpc" }
dependency "iam"     { config_path = "../iam" }
dependency "keypair" { config_path = "../keypair" }

terraform { source = "../../../../../modules/ec2" }

locals {
  cfg = read_json(find_in_parent_folders("inputs.json"))
}

inputs = {
  enabled        = try(local.cfg.modules.ec2.enabled, true)
  name           = try(local.cfg.modules.ec2.name, "ec2")
  ami_id         = try(local.cfg.modules.ec2.ami_id, null)
  instance_type  = try(local.cfg.modules.ec2.instance_type, "t3.micro")

  subnet_id            = dependency.vpc.outputs.private_subnet_ids[0]
  iam_instance_profile = try(dependency.iam.outputs.instance_profile_name, null)

  # use created key if present; else a predictable default
  key_name = coalesce(
    try(dependency.keypair.outputs.key_name, null),
    "${local.cfg.sandbox_name}-keypair"
  )

  tags_extra = merge(
    try(local.cfg.common_tags, {}),
    { RequestID = local.cfg.request_id, Requester = local.cfg.requester, Service = "EC2" }
  )
}
