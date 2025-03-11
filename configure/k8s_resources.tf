resource "kubernetes_namespace" "namespace1" {
  metadata {
    name = "namespace1"
  }
}

resource "kubernetes_namespace" "namespace2" {
  metadata {
    name = "namespace2"
  }
}

resource "kubernetes_service_account" "client_sa_namespace1" {
  metadata {
    name      = "client-service-account"
    namespace = kubernetes_namespace.namespace1.metadata[0].name
  }
}

resource "kubernetes_service_account" "client_sa_namespace2" {
  metadata {
    name      = "client-service-account"
    namespace = kubernetes_namespace.namespace2.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "vault_auth_role" {
  metadata {
    name = "vault-auth-role"
  }
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts", "pods", "namespaces"]
    verbs      = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "vault_auth_binding" {
  metadata {
    name = "vault-auth-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.vault_auth_role.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.client_sa_namespace1.metadata[0].name
    namespace = kubernetes_namespace.namespace1.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.client_sa_namespace2.metadata[0].name
    namespace = kubernetes_namespace.namespace2.metadata[0].name
  }
}
