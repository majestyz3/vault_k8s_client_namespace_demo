output "vault_k8s_auth_accessor" {
  value = data.vault_auth_backends.all.backends["kubernetes/"]
}

output "vault_shared_entity_id" {
  value = vault_identity_entity.shared_k8s_client.id
}
