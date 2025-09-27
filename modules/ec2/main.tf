############################################
# AMI selection: prefer input; else AL2 latest
############################################

# Latest Amazon Linux 2 from SSM Parameter Store
data "aws_ssm_parameter" "al2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# If a specific AMI id is provided, check whether it exists
locals {
  use_input_ami = var.ami_id != null && var.ami_id != ""
}

data "aws_ami_ids" "by_id" {
  count  = local.use_input_ami ? 1 : 0
  owners = ["self", "amazon"]
  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
}

locals {
  input_ami_exists = local.use_input_ami
    && length(data.aws_ami_ids.by_id) > 0
    && length(data.aws_ami_ids.by_id[0].ids) > 0

  effective_ami = local.input_ami_exists ? var.ami_id : data.aws_ssm_parameter.al2.value
}

############################################
# Security Group (egress-all, no public ingress)
############################################
resource "aws_security_group" "app" {
  count       = var.enabled ? 1 : 0
  name        = "${var.name}-sg"
  description = "EC2 SG (egress only)"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  count             = var.enabled ? 1 : 0
  security_group_id = aws_security_group.app[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All egress"
}

############################################
# EC2 Instances (round-robin across given subnets)
############################################
resource "aws_instance" "this" {
  count                  = var.enabled ? var.instance_count : 0

  ami                    = local.effective_ami
  instance_type          = var.instance_type
  subnet_id              = var.subnets[count.index % length(var.subnets)]
  vpc_security_group_ids = [aws_security_group.app[0].id]

  iam_instance_profile   = var.iam_instance_profile
  key_name               = var.key_name

  # Private-only; IMDSv2 required
  associate_public_ip_address = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = merge(
    local.common_tags,
    { Name = "${var.name}-${format("%02d", count.index + 1)}" }
  )
}
