# ------------------------------------------------------------------------------
# Fetch Remote State from Infra Deployment
# ------------------------------------------------------------------------------
data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "../infra/terraform.tfstate"  # current infrastucture tf file
  }
}
# ------------------------------------------------------------------------------
# Data Sources - Fetch Existing Infrastructure Information
# ------------------------------------------------------------------------------

data "aws_eks_cluster" "vault" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "vault" {
  name = var.eks_cluster_name
}



# ------------------------------------------------------------------------------
# Vault Kubernetes Authentication Backend Configuration
# ------------------------------------------------------------------------------

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = var.vault_k8s_auth_path
}

resource "vault_kubernetes_auth_backend_config" "k8s_auth" {
  backend            = "kubernetes"
  kubernetes_host    = var.eks_cluster_endpoint
  kubernetes_ca_cert = base64decode(var.eks_cluster_ca)  # Decode CA cert
}

# ------------------------------------------------------------------------------
# Vault Policy - Defines Access Rules for Applications
# ------------------------------------------------------------------------------

resource "vault_policy" "app_policy" {
  name   = var.vault_policy_name
  policy = <<EOT
path "secret/data/${var.app_namespace}/*" {
  capabilities = ["read", "list"]
}
EOT
}

# ------------------------------------------------------------------------------
# Vault Kubernetes Role - Maps Kubernetes Service Accounts to Vault Policies
# ------------------------------------------------------------------------------

resource "vault_kubernetes_auth_backend_role" "app_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = var.vault_role
  bound_service_account_names      = [kubernetes_service_account.app_sa.metadata[0].name]
  bound_service_account_namespaces = [kubernetes_namespace.app_ns.metadata[0].name]
  token_policies                   = [vault_policy.app_policy.name]  
}


# ------------------------------------------------------------------------------
# Kubernetes Namespace - Ensures Namespace Exists
# ------------------------------------------------------------------------------

resource "kubernetes_namespace" "app_ns" {
  metadata {
    name = var.app_namespace
  }
}

# ------------------------------------------------------------------------------
# Kubernetes Service Account - Used for Vault Authentication
# ------------------------------------------------------------------------------

resource "kubernetes_service_account" "app_sa" {
  metadata {
    name      = var.app_service_account
    namespace = kubernetes_namespace.app_ns.metadata[0].name
  }
}

# ------------------------------------------------------------------------------
# Kubernetes Deployment - Sample Application That Uses Vault
# ------------------------------------------------------------------------------

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "zarkesh-app"
    namespace = kubernetes_namespace.app_ns.metadata[0].name
    labels = {
      app = "zarkesh-app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "zarkesh-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "zarkesh-app"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.app_sa.metadata[0].name

        container {
          name  = "zarkesh-app"
          image = "hashicorp/vault-k8s-demo:latest"

          env {
            name  = "VAULT_ADDR"
            value = var.vault_addr
          }

          env {
            name  = "VAULT_ROLE"
            value = var.vault_role
          }

          env {
            name  = "APP_NAMESPACE"
            value = var.app_namespace
          }

          env {
            name  = "SECRET_PATH"
            value = var.vault_secret_path
          }

          env {
            name  = "SECRET_KEY"
            value = var.vault_secret_key
          }
        }
      }
    }
  }
}

# ------------------------------------------------------------------------------
# Kubernetes Service - Exposes the Application
# ------------------------------------------------------------------------------

resource "kubernetes_service" "app_service" {
  metadata {
    name      = "zarkesh-app-service"
    namespace = kubernetes_namespace.app_ns.metadata[0].name
  }

  spec {
    selector = {
      app = "zarkesh-app"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 8080
    }
  }
  
}

