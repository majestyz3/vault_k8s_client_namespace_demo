#!/bin/bash
set -e

VAULT_VERSION="${1:-1.19.0+ent}"
VAULT_LICENSE="${2}"

echo "🚀 Installing Vault ${VAULT_VERSION}"

# Install Vault
cd /tmp
curl -L -o vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"
unzip vault.zip
sudo mv vault /usr/local/bin/vault
sudo chmod +x /usr/local/bin/vault

# Verify Vault works
if ! /usr/local/bin/vault version; then
  echo "❌ Vault installation failed."
  exit 1
fi

# Add Vault to PATH (optional - just to be safe)
export PATH=$PATH:/usr/local/bin

# Write Vault configuration
sudo tee /etc/vault/vault.hcl <<EOF
storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

api_addr = "http://0.0.0.0:8200"

seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "REPLACE_WITH_YOUR_KMS_KEY_ID"
}

ui = true
EOF

# Write Vault License
sudo tee /etc/vault/vault.hclic <<EOF
${VAULT_LICENSE}
EOF

# Enable and Start Vault Service
sudo systemctl enable vault
sudo systemctl start vault

# Final sanity check - verify Vault is running
sleep 5
if ! curl -s http://127.0.0.1:8200/v1/sys/health | jq .; then
  echo "❌ Vault is not running correctly."
  exit 1
fi

echo "✅ Vault installed and started successfully!"

