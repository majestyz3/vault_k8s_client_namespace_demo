provider "aws" {
  region      = "us-east-1"
  access_key  = var.aws_access_key
  secret_key  = var.aws_secret_key
  token       = var.aws_session_token
}

provider "vault" {
  address = "http://${aws_instance.vault.public_ip}:8200"
}
