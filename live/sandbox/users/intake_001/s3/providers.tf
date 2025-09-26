terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Keep backend at the module for your current pattern (same as IAM)
  backend "s3" {
    bucket  = "wbd-tf-state-sandbox"
    key     = "wbd/sandbox/s3/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  # Align with IAM: take region from module input
  region = var.region
}
