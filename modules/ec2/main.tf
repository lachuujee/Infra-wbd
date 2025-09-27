########################################
# Naming & tags
########################################
locals {
  common_tags = merge(
    { Name = var.name },
    var.tags_extra
  )
}

########################################
# Upstream remote states (VPC, IAM, KeyPair)
########################################
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = var.vpc_state_key
    region = var.remote_state_region
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = var.iam_state_key
    region = var.remote_state_region
  }
}

data "terraform_remote_state" "keypair" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = var.keypair_state_key
    region = var.remote_state_region
  }
}

########################################
# AMI resolution
########################################
data "aws_ssm_parameter" "al2" {
  name = var.ami_ssm_parameter
}

locals {
  use_input_ami = (var.ami_id != null && var.ami_id != "")
}

# Validate input AMI ID if provided; otherwise skip
data "aws_ami_ids" "by_id" {
  count  = local.use_input_ami ? 1 : 0
  owners = ["self", "amazon"]

  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
}

locals {
  input_ami_exists = local.use_input_ami && length(data.aws_ami_ids.by_id) > 0 && length(data.aws_ami_ids.by_id[0].ids) > 0
  effective_ami    = local.input_ami_exists ? var.ami_id : data.aws_ssm_parameter.al2.value
}

########################################
# Subnet selection (prefer role keys app-a/app-b)
########################################
locals {
  # Map like { "app-a" = subnet-xxx, "app-b" = subnet-yyy, ... }
  by_role     = try(data.terraform_remote_state.vpc.outputs.private_subnet_ids_by_role, {})

  # gather preferred role subnets
  from_roles  = [for r in var.subnet_role_keys : try(local.by_role[r], null)]
  role_pair   = compact(local.from_roles)

  # fallback: list of all private subnets (first two)
  priv_list   = try(data.terraform_remote_state.vpc.outputs.private_subnet_ids, [])
  first_two   = length(local.priv_list) >= 2 ? slice(local.priv_list, 0, 2) : local.priv_list

  # final set used for placement
  subnets_for_use = length(local.role_pair) >= 2 ? local.role_pair : local.first_two

  vpc_id = try(data.terraform_remote_state.vpc.outputs.vpc_id, null)

  iam_instance_profile = try(data.terraform_remote_state.iam.outputs.instance_profile_name, null)
  key_name             = try(data.terraform_remote_state.keypair.outputs.key_name, null)
}

########################################
# Security Group: HTTPS in, all out
########################################
resource "aws_security_group" "app_sg" {
  count       = var.enabled ? 1 : 0
  name        = "${var.name}-sg"
  description = "EC2 app SG (443 only)"
  vpc_id      = local.vpc_id
  tags        = merge(local.common_tags, { Name = "${var.name}-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "https_in" {
  count             = var.enabled ? 1 : 0
  security_group_id = aws_security_group.app_sg[0].id
  cidr_ipv4         = "0.0.0.0/0" # tighten later if needed
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS"
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  count             = var.enabled ? 1 : 0
  security_group_id = aws_security_group.app_sg[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All egress"
}

########################################
# EC2 instances (spread across two subnets if multiple)
########################################
resource "aws_instance" "app" {
  count = (var.enabled && length(local.subnets_for_use) > 0) ? var.instance_count : 0

  ami                    = local.effective_ami
  instance_type          = var.instance_type
  subnet_id              = local.subnets_for_use[count.index % length(local.subnets_for_use)]
  vpc_security_group_ids = [aws_security_group.app_sg[0].id]

  # Optional: if key/profile exist, use them; null means "unset"
  key_name             = local.key_name
  iam_instance_profile = local.iam_instance_profile

  # Root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  # Metadata (IMDSv2)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Name tag: append index when creating multiple
  tags = merge(
    local.common_tags,
    {
      Name = var.instance_count > 1 ? "${var.name}-${count.index + 1}" : var.name
    }
  )
}
