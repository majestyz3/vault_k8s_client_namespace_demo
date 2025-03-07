

#!/bin/bash
set -e

# Variables
VAULT_VERSION="${1:-1.19.0}"
VAULT_LICENSE="${2}"
KMS_KEY_ID="${3}"

echo "🚀 Installing Vault ${VAULT_VERSION}"

# Fix Vault version string for URL
VAULT_BASE_URL="https://releases.hashicorp.com/vault"
VAULT_CLEAN_VERSION=$(echo "$VAULT_VERSION" | sed 's/+ent//')

VAULT_ZIP_URL="${VAULT_BASE_URL}/${VAULT_CLEAN_VERSION}/vault_${VAULT_CLEAN_VERSION}_linux_amd64.zip"

# Debugging output
echo "🔍 Downloading Vault from: $VAULT_ZIP_URL"

# Download Vault binary
curl -fsSL -o vault.zip "$VAULT_ZIP_URL"

# Check if the file exists and is valid
if [ ! -s vault.zip ]; then
  echo "❌ Error: Vault download failed. The file does not exist or is empty."
  exit 1
fi

unzip vault.zip
sudo mv vault /usr/local/bin/vault
sudo chmod +x /usr/local/bin/vault

# Verify Vault installation
if ! /usr/local/bin/vault version; then
  echo "❌ Vault installation failed."
  exit 1
fi

# Add Vault to PATH
export PATH=$PATH:/usr/local/bin

# Create necessary directories
sudo mkdir -p /etc/vault /opt/vault/data

# Write Vault configuration file
echo "📝 Writing Vault configuration..."
sudo tee /etc/vault/vault.hcl > /dev/null <<EOF
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
  kms_key_id = "${KMS_KEY_ID}"
}

ui = true
EOF

# Ensure Vault license file exists
echo "📝 Writing Vault license..."
sudo tee /etc/vault/vault.hclic > /dev/null <<EOF
${VAULT_LICENSE}
EOF

# Set permissions
sudo chmod 640 /etc/vault/vault.hcl
sudo chmod 640 /etc/vault/vault.hclic

# 🔧 **Ensure Vault systemd service file exists**
echo "🔧 Creating Vault systemd service..."
sudo tee /etc/systemd/system/vault.service > /dev/null <<EOF
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
After=network.target

[Service]
User=root
Group=root
ExecStart=/usr/local/bin/vault server -config=/etc/vault/vault.hcl
ExecReload=/bin/kill --signal HUP \$MAINPID
Restart=always
RestartSec=5
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize new service
sudo systemctl daemon-reload

# Enable and start Vault service
echo "🔄 Enabling and starting Vault service..."
sudo systemctl enable vault
sudo systemctl start vault

# Final check: Verify Vault is running
sleep 5
if ! curl -s http://127.0.0.1:8200/v1/sys/health | jq .; then
  echo "❌ Vault is not running correctly."
  exit 1
fi

echo "✅ Vault installed and started successfully!"
