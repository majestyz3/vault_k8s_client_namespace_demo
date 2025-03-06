resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "eks" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = var.eks_cluster_endpoint
  kubernetes_ca_cert = base64decode(var.eks_cluster_ca)
  token_reviewer_jwt = data.kubernetes_secret.vault_auth_token.data.token
}

resource "vault_policy" "app_policy" {
  name = "app-policy"

  policy = <<EOT
path "secret/data/app/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "app_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "app-role"
  bound_service_account_names      = ["app-service-account"]
  bound_service_account_namespaces = ["app-namespace"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.app_policy.name]
}

resource "kubernetes_service_account" "vault_auth" {
  metadata {
    name      = "vault-auth"
    namespace = "kube-system"
  }
}

resource "kubernetes_secret" "vault_auth_secret" {
  metadata {
    name      = "vault-auth-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.vault_auth.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}

data "kubernetes_secret" "vault_auth_token" {
  metadata {
    name      = kubernetes_secret.vault_auth_secret.metadata[0].name
    namespace = "kube-system"
  }
}
