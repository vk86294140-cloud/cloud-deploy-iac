terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }

  # For team use, switch to a remote backend so state is shared and locked.
  # Create the bucket + DynamoDB table once, then uncomment:
  #
  # backend "s3" {
  #   bucket         = "your-tfstate-bucket"
  #   key            = "cloud-deploy-iac/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "your-tf-lock-table"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}
