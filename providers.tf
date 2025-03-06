provider "aws" {
  region      = "us-east-1"
}

provider "vault" {
  address = "http://${aws_instance.vault.public_ip}:8200"
}
