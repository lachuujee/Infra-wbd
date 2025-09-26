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

# Region comes from var.region; fallback to us-east-1 if empty/null
provider "aws" {
  region = (trimspace(coalesce(var.region, "")) != "") ? var.region : "us-east-1"
}
