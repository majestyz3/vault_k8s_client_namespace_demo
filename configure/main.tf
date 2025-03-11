terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "vault" {
  address = "http://${var.vault_addr}:8200"
  token   = var.vault_root_token
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# ✅ Enable Kubernetes Authentication in Vault
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes"
}

# ✅ Configure Kubernetes Auth with EKS Cluster Details
resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://${var.eks_cluster_endpoint}"
  kubernetes_ca_cert = base64decode(var.eks_cluster_ca)
  token_reviewer_jwt = file("/var/run/secrets/kubernetes.io/serviceaccount/token")
}

# ✅ Create Kubernetes Auth Role for Namespace-Based Clients
resource "vault_kubernetes_auth_backend_role" "client_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "client-role"
  bound_service_account_names      = ["client-service-account"]
  bound_service_account_namespaces = ["namespace1", "namespace2"]
  alias_name_source                = "serviceaccountid"
  token_policies                   = ["default"]
}

# ✅ Create Vault Identity Entity for Shared Kubernetes Clients
resource "vault_identity_entity" "shared_k8s_client" {
  name   = "shared-k8s-client"
  policies = ["default"]
}

# ✅ Fetch Kubernetes Auth Backend Accessor
data "vault_auth_backends" "all" {}

# ✅ Create Entity Aliases for Each Namespace (Prevents Duplicate Clients)
resource "vault_identity_entity_alias" "namespace1_alias" {
  name           = "namespace1/client-service-account"
  canonical_id   = vault_identity_entity.shared_k8s_client.id
  mount_accessor = data.vault_auth_backends.all.backends["kubernetes/"]
}

resource "vault_identity_entity_alias" "namespace2_alias" {
  name           = "namespace2/client-service-account"
  canonical_id   = vault_identity_entity.shared_k8s_client.id
  mount_accessor = data.vault_auth_backends.all.backends["kubernetes/"]
}

# ✅ Define Policy for Kubernetes Workloads
resource "vault_policy" "k8s_policy" {
  name = "k8s-policy"

  policy = <<EOT
path "secret/data/k8s/*" {
  capabilities = ["read", "list"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "identity/entity/id/{{identity.entity.id}}" {
  capabilities = ["read"]
}

path "identity/entity-alias/id/{{identity.entity.alias_id}}" {
  capabilities = ["read"]
}
EOT
}

# ✅ Assign Policy to Shared Kubernetes Entity
resource "vault_identity_entity_policies" "shared_k8s_client_policy" {
  entity_id = vault_identity_entity.shared_k8s_client.id
  policies  = ["k8s-policy"]
}

