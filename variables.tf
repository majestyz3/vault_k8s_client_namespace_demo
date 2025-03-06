variable "aws_region" {
  description = "AWS region to deploy Vault in"
  type        = string
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
}

variable "aws_session_token" {
  description = "AWS Session Token (for temporary credentials)"
  type        = string
}

variable "vault_cluster_name" {
  description = "Name of the Vault cluster"
  type        = string
  default     = "vault-enterprise-demo"
}
