# Ensure VPC, IAM, and KeyPair apply before EC2 (order only)
dependencies {
  paths = ["../vpc", "../iam", "../keypair"]
}

terraform {
  source = "../../../../../modules/ec2"
}

locals {
  # Read inputs.json one level up
  inputs_path = "${get_terragrunt_dir()}/../inputs.json"
  cfg         = jsondecode(file(local.inputs_path))

  name_value     = try(local.cfg.modules.ec2.name, "${local.cfg.sandbox_name}-ec2")
  instance_count = try(local.cfg.modules.ec2.instance_count, try(local.cfg.modules.ec2.count, 1))
}

inputs = {
  # Enable EC2 only if the flag is true
  enabled = try(local.cfg.modules.ec2.enabled, false)

  # Region (defaults in module are us-east-1, but pass if present)
  region  = try(local.cfg.aws_region, "us-east-1")

  # Naming / tags
  name       = local.name_value
  tags_extra = {
    RequestID   = local.cfg.request_id
    Requester   = local.cfg.requester
    Environment = local.cfg.environment
    Service     = "EC2"
  }

  # EC2 parameters
  instance_count = local.instance_count
  instance_type  = try(local.cfg.modules.ec2.instance_type, "t2.micro")
  ami_id         = try(local.cfg.modules.ec2.ami_id, null)

  # NOTE: No dependency outputs or complex expressions here.
  # The module will pull VPC/IAM/KeyPair info via terraform_remote_state.
}
