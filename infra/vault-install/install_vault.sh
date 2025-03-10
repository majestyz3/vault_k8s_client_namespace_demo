#!/bin/bash
set -e

# Variables
VAULT_VERSION="${1:-1.19.0}"
VAULT_LICENSE="${2}"
KMS_KEY_ID="${3}"
IS_DR_VAULT="${4:-false}"  # Determines if this is a DR Vault
PRIMARY_VAULT_ADDR="${5:-}" # Needed for DR Vault

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

# Determine Vault configuration based on DR status
echo "📝 Writing Vault configuration..."
if [ "$IS_DR_VAULT" == "true" ]; then
    echo "🔄 Configuring Vault as a DR Secondary"
    sudo tee /etc/vault/vault.hcl > /dev/null <<EOF
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
  primary_api_addr = "${PRIMARY_VAULT_ADDR}"
}

seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "${KMS_KEY_ID}"
}

ui = true
EOF
else
    echo "🔄 Configuring Vault as a Primary Server"
    sudo tee /etc/vault/vault.hcl > /dev/null <<EOF
storage "raft" {
  path    = "/opt/vault/data"
  node_id = "primary-vault"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

api_addr = "http://0.0.0.0:8200"
cluster_addr = "http://0.0.0.0:8201"

seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "${KMS_KEY_ID}"
}

ui = true
EOF
fi

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

# Ensure jq is installed before checking Vault health
echo "🔧 Installing jq..."
sudo yum install -y jq

# Wait for Vault to be responsive before continuing
echo "⏳ Waiting for Vault to become available..."
for i in {1..10}; do
  if curl -s http://127.0.0.1:8200/v1/sys/health | jq .; then
    echo "✅ Vault is up and running!"
    break
  fi
  echo "⏳ Waiting for Vault to start... Attempt $i/10"
  sleep 5
done

# If this is the DR Vault, join it to the Primary
if [ "$IS_DR_VAULT" == "true" ]; then
    echo "🔄 Initializing DR Vault Replication..."

    # Wait for Primary Vault to be ready
    echo "⏳ Checking if Primary Vault is available at $PRIMARY_VAULT_ADDR..."
    until curl -s "${PRIMARY_VAULT_ADDR}/v1/sys/health" | jq .; do
      echo "⏳ Waiting for Primary Vault to be online..."
      sleep 5
    done
    echo "✅ Primary Vault is up!"

    # Fetch root token from the primary Vault
    echo "🔑 Fetching root token from Primary Vault..."
    PRIMARY_VAULT_TOKEN=$(ssh -o StrictHostKeyChecking=no -i /home/ec2-user/vault-demo-key.pem ec2-user@"$(echo $PRIMARY_VAULT_ADDR | sed 's|http://||g')" "cat /home/ec2-user/root-token.txt")
    export VAULT_TOKEN="$PRIMARY_VAULT_TOKEN"

    # Authenticate DR Vault to Primary Vault
    echo "🔐 Logging into Primary Vault from DR Vault..."
    vault login "$VAULT_TOKEN"

    # Join DR Vault to the Primary Vault
    echo "🔄 Joining DR Vault to the Primary Vault..."
    vault operator raft join "${PRIMARY_VAULT_ADDR}"

    echo "✅ DR Vault successfully joined the Primary Vault!"
fi

echo "✅ Vault installed and started successfully!"
