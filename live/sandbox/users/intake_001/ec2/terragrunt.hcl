dependency "vpc"     { config_path = "../vpc" }
dependency "iam"     { config_path = "../iam" }
dependency "keypair" { config_path = "../keypair" }

terraform {
  source = "../../../../../modules/ec2"
}

locals {
  # Simple fix: load inputs.json as tfvars
  cfg = read_tfvars_file(find_in_parent_folders("inputs.json"))
}

inputs = {
  # pass region into the module (keeps all stacks consistent)
  region        = try(local.cfg.aws_region, "us-east-1")

  enabled       = try(local.cfg.modules.ec2.enabled, true)
  name          = try(local.cfg.modules.ec2.name, "ec2")
  ami_id        = try(local.cfg.modules.ec2.ami_id, null)
  instance_type = try(local.cfg.modules.ec2.instance_type, "t3.micro")

  subnet_id            = dependency.vpc.outputs.private_subnet_ids[0]
  iam_instance_profile = try(dependency.iam.outputs.instance_profile_name, null)

  # fallback uses sandbox_name if present, else "sandbox"
  key_name = coalesce(
    try(dependency.keypair.outputs.key_name, null),
    "${try(local.cfg.sandbox_name, "sandbox")}-keypair"
  )

  tags_extra = merge(
    try(local.cfg.common_tags, {}),
    {
      RequestID = try(local.cfg.request_id, "unknown")
      Requester = try(local.cfg.requester, "unknown")
      Service   = "EC2"
    }
  )
}
