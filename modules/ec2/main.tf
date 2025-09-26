#####################################
# AMI: prefer input; else AL2 latest
#####################################

# Latest Amazon Linux 2 from AWS public SSM Param Store
data "aws_ssm_parameter" "al2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# If user passed an AMI ID, *non-error* check whether it exists
# (aws_ami_ids returns [] when not found, so we can safely fall back)
locals {
  input_ami = (
    var.ami_id != null && trimspace(var.ami_id) != ""
  ) ? trimspace(var.ami_id) : null
}

data "aws_ami_ids" "by_id" {
  count = local.input_ami != null ? 1 : 0
  # restrict search to common owners; remove if you allow 3p AMIs
  owners = ["self", "amazon"]
  filter {
    name   = "image-id"
    values = [local.input_ami]
  }
}

locals {
  input_ami_exists = (
    length(data.aws_ami_ids.by_id) > 0 &&
    length(data.aws_ami_ids.by_id[0].ids) > 0
  )
  effective_ami = local.input_ami_exists ? local.input_ami : data.aws_ssm_parameter.al2.value
}

###################
# Security Group
###################
resource "aws_security_group" "app_sg" {
  count       = var.enabled ? 1 : 0
  name        = "${var.name}-sg"
  description = "EC2 SG (443 only)"
  vpc_id      = null # set at root if you want; or keep rules only
  tags        = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "https_in" {
  count             = var.enabled ? 1 : 0
  security_group_id = aws_security_group.app_sg[0].id
  cidr_ipv4         = "0.0.0.0/0"      # change to VPC CIDR if you prefer internal only
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

#############
# EC2
#############
resource "aws_instance" "this" {
  count                = var.enabled ? 1 : 0
  ami                  = local.effective_ami
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  vpc_security_group_ids = [aws_security_group.app_sg[0].id]

  # Attach IAM + KeyPair when provided (nulls are simply ignored by provider)
  iam_instance_profile = var.iam_instance_profile
  key_name             = var.key_name

  # Root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  # IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = local.common_tags
}

