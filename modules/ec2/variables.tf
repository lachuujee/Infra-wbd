variable "enabled" {
  type    = bool
  default = true
}

variable "name" {
  type    = string
  default = "ec2"
}

# If provided via inputs.json, we'll try to use it; else we fall back to AL2 via SSM
variable "ami_id" {
  type    = string
  default = null
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

# From VPC stack (private subnet)
variable "subnet_id" {
  type = string
}

# From IAM stack (instance profile name)
variable "iam_instance_profile" {
  type    = string
  default = null
}

# From KeyPair stack (key name to attach)
variable "key_name" {
  type    = string
  default = null
}

# Optional extra tags
variable "tags_extra" {
  type    = map(string)
  default = {}
}

locals {
  common_tags = merge(
    {
      Name = var.name
    },
    var.tags_extra
  )
}
