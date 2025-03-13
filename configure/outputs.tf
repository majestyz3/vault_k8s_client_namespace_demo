# ------------------------------------------------------------------------------
# Terraform Outputs - Expose Key Information
# ------------------------------------------------------------------------------

# EKS Cluster Outputs
output "eks_cluster_endpoint" {
  description = "EKS Cluster API Endpoint"
  value       = data.terraform_remote_state.infra.outputs.eks_cluster_endpoint
}

output "eks_cluster_ca" {
  description = "EKS Cluster Certificate Authority"
  value       = data.terraform_remote_state.infra.outputs.eks_cluster_ca
}

# Vault Server Outputs
output "vault_server_address" {
  description = "Vault server HTTP API endpoint"
  value       = var.vault_addr
}

# Kubernetes Namespace & Service Account
output "app_namespace" {
  description = "Kubernetes namespace for the application"
  value       = var.app_namespace
}

output "app_service_account" {
  description = "Kubernetes Service Account for Vault authentication"
  value       = var.app_service_account
}

# Vault Kubernetes Auth Configuration
output "vault_kubernetes_auth_config" {
  description = "Vault Kubernetes authentication backend configuration"
  value = {
    kubernetes_host    = data.terraform_remote_state.infra.outputs.eks_cluster_endpoint
    kubernetes_ca_cert = data.terraform_remote_state.infra.outputs.eks_cluster_ca
  }
}

# Vault Role & Policy Outputs
output "vault_role" {
  description = "Vault role assigned to the application"
  value       = var.vault_role
}

output "vault_policy" {
  description = "Vault policy associated with the application"
  value       = var.vault_policy_name
}

# Vault Secret Configuration
output "vault_secret_path" {
  description = "Path to the secret in Vault"
  value       = var.vault_secret_path
}

output "vault_secret_key" {
  description = "Key used for retrieving secret data"
  value       = var.vault_secret_key
}
