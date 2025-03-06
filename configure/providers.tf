provider "vault" {
  address = var.vault_address
  token   = var.vault_root_token
}

provider "kubernetes" {
  host                   = var.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(var.eks_cluster_ca)
}