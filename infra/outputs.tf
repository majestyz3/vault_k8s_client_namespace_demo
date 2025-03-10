# ------------------------------------------------------------------------------
# Vault Server Outputs
# ------------------------------------------------------------------------------
output "vault_address" {
  description = "Public API Address of the Primary Vault server"
  value       = "http://${aws_instance.vault.public_ip}:8200"
}

output "vault_dr_address" {
  description = "Public API Address of the Disaster Recovery Vault server"
  value       = "http://${aws_instance.vault_dr.public_ip}:8200"
}

output "vault_public_ip" {
  description = "Public IP of the Primary Vault server"
  value       = aws_instance.vault.public_ip
}

output "vault_dr_public_ip" {
  description = "Public IP of the DR Vault server"
  value       = aws_instance.vault_dr.public_ip
}

# ------------------------------------------------------------------------------
# Security Settings
# ------------------------------------------------------------------------------
output "allowed_ssh_ip" {
  description = "Whitelisted IP for SSH access"
  value       = var.allowed_ssh_ip
}

# ------------------------------------------------------------------------------
# EKS Outputs
# ------------------------------------------------------------------------------
output "eks_cluster_endpoint" {
  description = "EKS Cluster API Endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_ca" {
  description = "EKS Cluster Certificate Authority Data"
  value       = module.eks.cluster_certificate_authority_data
}

# ------------------------------------------------------------------------------
# AWS KMS Outputs
# ------------------------------------------------------------------------------
output "vault_auto_unseal_kms_key_arn" {
  description = "ARN of the Vault Auto-Unseal KMS key"
  value       = aws_kms_key.vault_auto_unseal.arn
}

# ------------------------------------------------------------------------------
# Vault Credentials Outputs (Manually Pulled)
# ------------------------------------------------------------------------------
output "vault_root_token" {
  description = "The initial Vault root token (retrieved manually)"
  value       = fileexists("${path.module}/root-token-primary.txt") ? trimspace(file("${path.module}/root-token-primary.txt")) : "Root token not available"
  sensitive   = true
}

output "vault_unseal_keys" {
  description = "The Vault unseal keys (retrieved manually)"
  value       = fileexists("${path.module}/unseal-keys-primary.txt") ? trimspace(file("${path.module}/unseal-keys-primary.txt")) : "Unseal keys not available"
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Disaster Recovery (DR) Vault Credentials Outputs
# ------------------------------------------------------------------------------
output "vault_dr_root_token" {
  description = "The initial Disaster Recovery Vault root token (retrieved manually)"
  value       = fileexists("${path.module}/root-token-dr.txt") ? trimspace(file("${path.module}/root-token-dr.txt")) : "Root token not available"
  sensitive   = true
}

output "vault_dr_unseal_keys" {
  description = "The Disaster Recovery Vault unseal keys (retrieved manually)"
  value       = fileexists("${path.module}/unseal-keys-dr.txt") ? trimspace(file("${path.module}/unseal-keys-dr.txt")) : "Unseal keys not available"
  sensitive   = true
}

# ------------------------------------------------------------------------------
# SSH Connection Commands (For Convenience)
# ------------------------------------------------------------------------------
output "ssh_primary_vault" {
  description = "Command to SSH into Primary Vault"
  value       = "ssh -i ${var.ssh_private_key} ec2-user@${aws_instance.vault.public_ip}"
}

output "ssh_dr_vault" {
  description = "Command to SSH into DR Vault"
  value       = "ssh -i ${var.ssh_private_key} ec2-user@${aws_instance.vault_dr.public_ip}"
}

