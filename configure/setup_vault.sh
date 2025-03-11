#!/bin/bash
set -e

# Ensure Vault is running
export VAULT_ADDR="http://127.0.0.1:8200"
vault login "$VAULT_ROOT_TOKEN"

# Enable Kubernetes Authentication
echo "🔑 Enabling Kubernetes authentication in Vault..."
vault auth enable kubernetes || true

# Configure Kubernetes Auth with EKS Cluster Details
echo "🔧 Configuring Kubernetes authentication method..."
vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://$(kubectl get service kubernetes -o jsonpath='{.spec.clusterIP}')" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Create Kubernetes Auth Role with serviceaccountid as alias source
echo "🔧 Creating Kubernetes authentication role..."
vault write auth/kubernetes/role/client-role \
    bound_service_account_names="client-service-account" \
    bound_service_account_namespaces="namespace1,namespace2" \
    alias_name_source="serviceaccountid" \
    policies="default"

# Create a Shared Vault Entity for the Kubernetes Client
echo "👤 Creating shared Vault entity for Kubernetes workloads..."
vault write identity/entity name="shared-k8s-client"
ENTITY_ID=$(vault read -field=id identity/entity/name/shared-k8s-client)

# Retrieve Kubernetes Auth Accessor
echo "🔍 Fetching Kubernetes auth accessor..."
KUBE_AUTH_ACCESSOR=$(vault auth list -format=json | jq -r '.["kubernetes/"].accessor')

# Create Entity Aliases for Each Namespace
echo "🔗 Mapping Kubernetes service accounts to the shared Vault entity..."
vault write identity/entity-alias name="namespace1/client-service-account" \
    canonical_id="$ENTITY_ID" \
    mount_accessor="$KUBE_AUTH_ACCESSOR"

vault write identity/entity-alias name="namespace2/client-service-account" \
    canonical_id="$ENTITY_ID" \
    mount_accessor="$KUBE_AUTH_ACCESSOR"

echo "✅ Vault setup completed successfully!"
