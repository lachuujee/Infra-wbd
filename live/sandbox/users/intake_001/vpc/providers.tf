terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  backend "s3" {
    bucket  = "wbd-tf-state-sandbox"
    key     = "wbd/sandbox/vpc/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  # default region if not provided
  region = var.region != null ? var.region : "us-east-1"
}
