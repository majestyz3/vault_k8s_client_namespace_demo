terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.10"
    }
  }

  backend "local" {}
}

# Kubernetes Provider
provider "kubernetes" {
  host                   = var.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(var.eks_cluster_ca)
  token                  = data.external.eks_auth_token.result.token
}

data "external" "eks_auth_token" {
  program = ["sh", "-c", "aws eks get-token --cluster-name ${var.eks_cluster_name} --region us-east-1 --output json | jq -n --arg token \"$(aws eks get-token --cluster-name ${var.eks_cluster_name} --region us-east-1 --output json | jq -r '.status.token')\" '{\"token\": $token}'"]
}



# Vault Provider
provider "vault" {
  address = var.vault_addr
  token   = var.vault_token
}

