 output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_ca" {
  description = "EKS Cluster Certificate Authority Data"
  value       = module.eks.cluster_certificate_authority_data
}
 

output "vault_public_ip" {
  description = "Public IP of the Vault instance"
  value       = aws_instance.vault.public_ip
}

output "vault_private_ip" {
  description = "Private IP of the Vault instance"
  value       = aws_instance.vault.private_ip
}

output "vault_auto_unseal_kms_key_arn" {
  description = "ARN of the KMS key used for Vault auto-unseal"
  value       = aws_kms_key.vault_auto_unseal.arn
}

output "vault_ssh_access" {
  description = "SSH access command for the Vault instance"
  value       = "ssh -i vault-demo-key.pem ec2-user@${aws_instance.vault.public_ip}"
}

output "vault_ui_access" {
  description = "Vault UI URL"
  value       = "http://${aws_instance.vault.public_ip}:8200"
}

output "private_subnets_cidr_blocks" {
  value = module.vpc.private_subnets_cidr_blocks
}
