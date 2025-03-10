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
}


provider "vault" {
  address = "http://${aws_instance.vault.public_ip}:8200"
}

provider "vault" {
  alias   = "dr"
  address = "http://${aws_instance.vault_dr.public_ip}:8200"
}
