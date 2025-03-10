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

variable "vault_address" {
  description = "Vault Enterprise primary cluster address"
  type        = string
  default     = ""
}

variable "vault_dr_address" {
  description = "Vault Enterprise disaster recovery cluster address"
  type        = string
  default     = ""
}

variable "allowed_ssh_ip" {
  description = "IP address allowed for SSH access (dynamically assigned from script)"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "AWS KMS Key ID for Vault Auto-Unseal"
  type        = string
  default     = ""
}

variable "my_ip" {
  description = "Your public IP address for SSH and API access"
  type        = string
}




