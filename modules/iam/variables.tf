variable "enabled" {
  type    = bool
  default = true
}

variable "name" {
  type    = string
  default = "iam"
}

variable "role_name" {
  type    = string
  default = "tg-exec-role"
}

# Which AWS services can assume this role (trust policy)
variable "assume_services" {
  type    = list(string)
  default = ["ec2.amazonaws.com"]
}

# Managed policies to attach to the role
variable "managed_policy_arns" {
  type    = list(string)
  default = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

# Role path
variable "path" {
  type    = string
  default = "/"
}

# Extra tags merged into all resources
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
