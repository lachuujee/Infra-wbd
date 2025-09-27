# Basic controls
variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "enabled" {
  type        = bool
  description = "Whether to create EC2 resources"
  default     = false
}

variable "name" {
  type        = string
  description = "Base name for the EC2 instance(s) and SG"
  default     = "ec2"
}

variable "instance_count" {
  type        = number
  description = "How many EC2 instances to create"
  default     = 1
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "ami_id" {
  type        = string
  description = "Optional explicit AMI ID. If empty, use latest Amazon Linux 2 via SSM"
  default     = null
}

variable "ami_ssm_parameter" {
  type        = string
  description = "SSM parameter path for latest AL2 AMI"
  default     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

variable "tags_extra" {
  type        = map(string)
  description = "Extra tags merged into all resources"
  default     = {}
}

# Remote state wiring (defaults match your current backends)
variable "remote_state_bucket" {
  type        = string
  description = "S3 bucket holding Terraform states of sibling stacks"
  default     = "wbd-tf-state-sandbox"
}

variable "remote_state_region" {
  type        = string
  description = "Region of the remote state bucket"
  default     = "us-east-1"
}

variable "vpc_state_key" {
  type        = string
  description = "S3 key for the VPC stack state"
  default     = "wbd/sandbox/vpc/terraform.tfstate"
}

variable "iam_state_key" {
  type        = string
  description = "S3 key for the IAM stack state"
  default     = "wbd/sandbox/iam/terraform.tfstate"
}

variable "keypair_state_key" {
  type        = string
  description = "S3 key for the KeyPair stack state"
  default     = "wbd/sandbox/keypair/terraform.tfstate"
}

# Which role-labelled private subnets to prefer when present
variable "subnet_role_keys" {
  type        = list(string)
  description = "Preferred role keys from private_subnet_ids_by_role"
  default     = ["app-a", "app-b"]
}
