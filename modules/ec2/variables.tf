variable "region" {
  type        = string
  description = "AWS region"
}

variable "enabled" {
  type    = bool
  default = false
}

# Display base name (e.g., sbx_intake_id_001-ec2)
variable "name" {
  type    = string
  default = "ec2"
}

# VPC + subnets (IDs)
variable "vpc_id" {
  type = string
}

variable "subnets" {
  type    = list(string)
  default = []
  # Expect at least one subnet when enabled; Terragrunt passes them in.
}

# IAM instance profile name (from IAM module output)
variable "iam_instance_profile" {
  type    = string
  default = null
}

# EC2 KeyPair name (from KeyPair module output)
variable "key_name" {
  type    = string
  default = null
}

# EC2 sizing / image
variable "instance_count" {
  type    = number
  default = 1
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami_id" {
  type    = string
  default = null   # If null/empty → fallback to AL2 latest
}

# Extra tags merged into all resources
variable "tags_extra" {
  type    = map(string)
  default = {}
}

locals {
  common_tags = merge(
    { Name = var.name },
    var.tags_extra
  )
}
