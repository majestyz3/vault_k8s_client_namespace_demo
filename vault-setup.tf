resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "eks" {
  backend = vault_auth_backend.kubernetes.path

  kubernetes_host    = var.eks_api_server
  kubernetes_ca_cert = base64decode(var.eks_ca_cert)
  token_reviewer_jwt = var.eks_token
}

resource "vault_identity_entity" "crm_service" {
  name = "crm-service"
}

resource "vault_identity_entity_alias" "namespace1_alias" {
  name            = "namespace1/crm-service-account"
  canonical_id    = vault_identity_entity.crm_service.id
  mount_accessor  = vault_auth_backend.kubernetes.accessor
}

resource "vault_policy" "app_policy" {
  name   = "app-policy"
  policy = <<EOT
path "secret/*" {
  capabilities = ["read", "list"]
}
EOT
}
