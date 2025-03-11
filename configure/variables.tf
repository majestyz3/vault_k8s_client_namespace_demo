variable "vault_addr" {
  description = "Vault server address"
  type        = string
  default     = "127.0.0.1"
}

variable "vault_root_token" {
  description = "Vault root token"
  type        = string
}

variable "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  type        = string
}

variable "eks_cluster_ca" {
  description = "EKS cluster CA certificate"
  type        = string
}
