#!/bin/bash
set -e

VAULT_VERSION="${VAULT_VERSION}"
VAULT_LICENSE="${VAULT_LICENSE}"
KMS_KEY_ID="${KMS_KEY_ID}"
AWS_REGION="${AWS_REGION}"
PRIMARY_VAULT_IP="${PRIMARY_VAULT_IP}"

echo "🚀 Installing Vault ${VAULT_VERSION} as a DR Secondary"

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
sudo mkdir -p /etc/vault

sudo tee /etc/vault/vault.hcl <<EOF
storage "raft" {
  path    = "/opt/vault/data"
  node_id = "dr-vault"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

replication {
  performance_secondary = true
  primary_api_addr = "$${PRIMARY_VAULT_IP}"
}

seal "awskms" {
  region     = "$${AWS_REGION}"
  kms_key_id = "$${KMS_KEY_ID}"
}

ui = true
EOF

# Write Vault License
sudo tee /etc/vault/vault.hclic <<EOF
$${VAULT_LICENSE}
EOF

# Ensure Vault data directory exists
sudo mkdir -p /opt/vault/data

# Enable and Start Vault Service
sudo systemctl enable vault
sudo systemctl start vault

# Sleep to allow Vault time to start
sleep 10

# Final sanity check - verify Vault is running
if ! curl -s http://127.0.0.1:8200/v1/sys/health | jq .; then
  echo "❌ Vault is not running correctly."
  exit 1
fi

echo "✅ Vault installed and started successfully as a DR Secondary!"

