terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # Authentication via Doormat Credential Server (assumes AWS_CONTAINER_CREDENTIALS_FULL_URI is set)
}
