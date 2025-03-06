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
  value       = fileexists("${path.root}/unseal-keys.txt") ? file("${path.root}/unseal-keys.txt") : "Unseal keys file not found (check provisioning)."
  sensitive   = true
}

output "vault_root_token" {
  description = "Vault root token (captured from remote server after init)"
  value       = fileexists("${path.root}/root-token.txt") ? file("${path.root}/root-token.txt") : "Root token file not found (check provisioning)."
  sensitive   = true
}

