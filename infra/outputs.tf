output "vault_public_ip" {
  description = "Public IP of the Vault EC2 instance"
  value       = aws_eip.vault.public_ip
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster API Endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_ca" {
  description = "EKS Cluster Certificate Authority Data"
  value       = module.eks.cluster_certificate_authority_data
}

output "vault_auto_unseal_kms_key_arn" {
  description = "ARN of the Vault Auto-Unseal KMS key"
  value       = aws_kms_key.vault_auto_unseal.arn
}