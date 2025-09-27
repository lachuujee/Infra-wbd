terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Keep state per-stack
  backend "s3" {
    bucket  = "wbd-tf-state-sandbox"
    key     = "wbd/sandbox/ec2/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# Region comes from the module input
provider "aws" {
  region = var.region
}
