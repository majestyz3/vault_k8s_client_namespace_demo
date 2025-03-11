variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "ssh_private_key" {
  description = "Path to the SSH private key"
  type        = string
}

variable "vault_license" {
  description = "Vault Enterprise License (from terraform.tfvars)"
  type        = string
}

variable "my_ip" {
  description = "Your public IP address to allow access to Vault"
  type        = string
}
