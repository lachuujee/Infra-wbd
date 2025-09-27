# Ensure VPC, IAM, and KeyPair are applied first
dependencies {
  paths = ["../vpc", "../iam", "../keypair"]
}

terraform {
  source = "../../../../../modules/ec2"
}

# Wire in outputs from sibling stacks
dependency "vpc" {
  config_path = "../vpc"
}

dependency "iam" {
  config_path = "../iam"
}

dependency "keypair" {
  config_path = "../keypair"
}

locals {
  # inputs.json lives one level up
  inputs_path = "${get_terragrunt_dir()}/../inputs.json"
  cfg         = jsondecode(file(local.inputs_path))

  # Prefer app-a/app-b subnets, else fall back to first two private subnets
  subnet_a      = try(dependency.vpc.outputs.private_subnet_ids_by_role["app-a"], null)
  subnet_b      = try(dependency.vpc.outputs.private_subnet_ids_by_role["app-b"], null)
  subnets_pref  = compact([local.subnet_a, local.subnet_b])
  final_subnets = length(local.subnets_pref) >= 2 ? local.subnets_pref : slice(dependency.vpc.outputs.private_subnet_ids, 0, 2)

  # Instance count: prefer modules.ec2.instance_count, else .count, else 1
  instance_count = try(local.cfg.modules.ec2.instance_count,
                   try(local.cfg.modules.ec2.count, 1))

  # Module display/name
  name_value = try(local.cfg.modules.ec2.name, "${local.cfg.sandbox_name}-ec2")
}

inputs = {
  enabled  = try(local.cfg.modules.ec2.enabled, false)
  region   = try(local.cfg.aws_region, "us-east-1")

  # Naming / tags
  name      = local.name_value
  tags_extra = {
    RequestID   = local.cfg.request_id
    Requester   = local.cfg.requester
    Environment = local.cfg.environment
    Service     = "EC2"
  }

  # EC2 params
  instance_count = local.instance_count
  instance_type  = try(local.cfg.modules.ec2.instance_type, "t2.micro")
  ami_id         = try(local.cfg.modules.ec2.ami_id, null)

  # From dependencies (state outputs)
  vpc_id               = dependency.vpc.outputs.vpc_id
  subnets              = local.final_subnets
  iam_instance_profile = dependency.iam.outputs.instance_profile_name
  key_name             = dependency.keypair.outputs.key_name
}
