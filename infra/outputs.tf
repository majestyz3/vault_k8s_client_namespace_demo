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
