output "kubernetes_auth_backend_path" {
  value       = vault_auth_backend.kubernetes.path
  description = "The path where the Kubernetes auth backend is enabled in Vault."
}

output "vault_policy_name" {
  value       = vault_policy.app_policy.name
  description = "The name of the Vault policy created for the app."
}

output "kubernetes_auth_role_name" {
  value       = vault_kubernetes_auth_backend_role.app_role.role_name
  description = "The name of the Kubernetes auth backend role created."
}

output "vault_auth_service_account_name" {
  value       = kubernetes_service_account.vault_auth.metadata[0].name
  description = "The Kubernetes ServiceAccount created for Vault auth."
}

output "vault_auth_service_account_namespace" {
  value       = kubernetes_service_account.vault_auth.metadata[0].namespace
  description = "The namespace where the Vault auth ServiceAccount was created."
}
