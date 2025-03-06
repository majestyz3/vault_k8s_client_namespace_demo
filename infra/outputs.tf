output "vault_public_ip" {
  description = "Public IP of the Vault EC2 instance"
  value       = aws_instance.vault.public_ip
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_ca" {
  description = "CA Certificate for the EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "vault_unseal_keys" {
  description = "Vault unseal keys (captured from remote server after init)"
  value       = file("./unseal-keys.txt")
  sensitive   = true
}

output "vault_root_token" {
  description = "Vault root token (captured from remote server after init)"
  value       = file("./root-token.txt")
  sensitive   = true
}
