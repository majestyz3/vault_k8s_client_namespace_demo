resource "kubernetes_deployment" "test_app" {
  metadata {
    name      = "test-app"
    namespace = kubernetes_namespace.namespace1.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "test-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "test-app"
        }
      }
      spec {
        service_account_name = kubernetes_service_account.client_sa_namespace1.metadata[0].name
        container {
          name  = "test-app"
          image = "alpine"
          command = ["/bin/sh", "-c"]
          args = [
            "apk add --no-cache curl jq; \
            export VAULT_ADDR='http://vault.vault.svc.cluster.local:8200'; \
            curl --request POST --data '{\"role\":\"client-role\", \"jwt\":\"$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq ."
          ]
        }
      }
    }
  }
}
