# Ensure VPC, IAM, and KeyPair are applied first
dependencies {
  paths = ["../vpc", "../iam", "../keypair"]
}

terraform {
  source = "../../../../../modules/ec2"
}

# Read outputs from sibling stacks
dependency "vpc" {
  config_path = "../vpc"
}

dependency "iam" {
  config_path = "../iam"
}

dependency "keypair" {
  config_path = "../keypair"
}

# Only keep locals that do NOT reference dependency.*
locals {
  inputs_path = "${get_terragrunt_dir()}/../inputs.json"
  cfg         = jsondecode(file(local.inputs_path))
}

# All dependency-based logic happens here (inputs), not in locals
inputs = {
  # Toggle
  enabled = try(local.cfg.modules.ec2.enabled, false)

  # Region (defaults if not present in JSON)
  region  = try(local.cfg.aws_region, "us-east-1")

  # Naming / tags
  name = try(local.cfg.modules.ec2.name, "${local.cfg.sandbox_name}-ec2")
  tags_extra = {
    RequestID   = local.cfg.request_id
    Requester   = local.cfg.requester
    Environment = local.cfg.environment
    Service     = "EC2"
  }

  # Count / shape / AMI
  instance_count = try(local.cfg.modules.ec2.instance_count,
                   try(local.cfg.modules.ec2.count, 1))
  instance_type  = try(local.cfg.modules.ec2.instance_type, "t2.micro")
  ami_id         = try(local.cfg.modules.ec2.ami_id, null)

  # Wire from VPC/IAM/KeyPair states
  vpc_id = dependency.vpc.outputs.vpc_id

  # Prefer app-a + app-b; if missing, fall back to first two private subnets
  subnets = length(compact([
              try(dependency.vpc.outputs.private_subnet_ids_by_role["app-a"], null),
              try(dependency.vpc.outputs.private_subnet_ids_by_role["app-b"], null)
            ])) >= 2
            ? compact([
                try(dependency.vpc.outputs.private_subnet_ids_by_role["app-a"], null),
                try(dependency.vpc.outputs.private_subnet_ids_by_role["app-b"], null)
              ])
            : slice(dependency.vpc.outputs.private_subnet_ids, 0, 2)

  iam_instance_profile = dependency.iam.outputs.instance_profile_name
  key_name             = dependency.keypair.outputs.key_name
}
