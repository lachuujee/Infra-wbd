terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # State for this VPC stack
  backend "s3" {
    bucket  = "wbd-tf-state-sandbox"
    key     = "wbd/sandbox/vpc/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# Region logic:
# - If Terragrunt passes var.region (from inputs.json.aws_region), use it
# - Else default to us-east-1
provider "aws" {
  region = var.region != null && trim(var.region) != "" ? var.region : "us-east-1"
}
