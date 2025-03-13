# ------------------------------------------------------------------------------
# General Variables
# ------------------------------------------------------------------------------

# AWS Region
variable "aws_region" {
  description = "The AWS region where resources are deployed"
  type        = string
  default     = "us-east-1"
}

# ------------------------------------------------------------------------------
# EKS Cluster Variables
# ------------------------------------------------------------------------------

variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "eks_cluster_endpoint" {
  description = "The API endpoint of the EKS cluster"
  type        = string
}

variable "eks_cluster_ca" {
  description = "The base64-encoded CA certificate of the EKS cluster"
  type        = string
}
# ------------------------------------------------------------------------------
# Vault Configuration Variables
# ------------------------------------------------------------------------------

variable "vault_addr" {
  description = "The address of the Vault server"
  type        = string
}

variable "vault_token" {
  description = "The Vault root token used for authentication"
  type        = string
}

variable "vault_namespace" {
  description = "The namespace in Vault where policies and roles are created"
  type        = string
  default     = "admin"
}

# ------------------------------------------------------------------------------
# Kubernetes Variables
# ------------------------------------------------------------------------------

variable "app_namespace" {
  description = "The Kubernetes namespace where the application is deployed"
  type        = string
  default     = "zarkesh-app"
}

variable "app_service_account" {
  description = "The Kubernetes service account name used by the application"
  type        = string
  default     = "zarkesh-sa"
}

# ------------------------------------------------------------------------------
# Vault Kubernetes Authentication Variables
# ------------------------------------------------------------------------------

variable "vault_k8s_auth_path" {
  description = "The path where the Kubernetes authentication backend is enabled in Vault"
  type        = string
  default     = "auth/kubernetes"
}

variable "vault_role" {
  description = "The name of the Vault role assigned to the application"
  type        = string
  default     = "zarkesh-role"
}

variable "vault_policy_name" {
  description = "The name of the Vault policy assigned to the application"
  type        = string
  default     = "zarkesh-app-policy"
}

# ------------------------------------------------------------------------------
# Secrets Path Variables
# ------------------------------------------------------------------------------

variable "vault_secret_path" {
  description = "The path in Vault where application secrets are stored"
  type        = string
  default     = "secret/data/zarkesh-app"
}

variable "vault_secret_key" {
  description = "The key name of the secret stored in Vault"
  type        = string
  default     = "password"
}

variable "vault_secret_value" {
  description = "The value of the secret stored in Vault"
  type        = string
  default     = "SuperSecretPassword123"
}

