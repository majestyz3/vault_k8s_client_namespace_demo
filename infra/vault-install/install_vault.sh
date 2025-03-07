#!/bin/bash
set -e

echo "📦 Installing dependencies..."
sudo yum install -y jq unzip

echo "⬇️ Downloading Vault 1.19 Enterprise..."
VAULT_VERSION="1.19.0+ent"
curl -o /tmp/vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"

echo "📂 Extracting Vault binary..."
sudo unzip -o /tmp/vault.zip -d /usr/local/bin/

echo "🔒 Making Vault executable..."
sudo chmod +x /usr/local/bin/vault

echo "🔗 Adding Vault to system PATH via symlink..."
sudo ln -sf /usr/local/bin/vault /usr/bin/vault

echo "✅ Vault version installed:"
vault --version

echo "🛠️ Checking for required files..."

if [ ! -f /home/ec2-user/vault-config.hcl ]; then
    echo "❌ Missing vault-config.hcl"
    exit 1
fi

if [ ! -f /home/ec2-user/vault.hclic ]; then
    echo "❌ Missing vault.hclic"
    exit 1
fi

echo "📂 Moving Vault license and config into place..."
sudo mv /home/ec2-user/vault.hclic /etc/vault.hclic
sudo cp /home/ec2-user/vault-config.hcl /etc/vault.hcl

echo "🛠️ Configuring Vault systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
After=network.target

[Service]
ExecStart=/usr/local/bin/vault server -config=/etc/vault.hcl
Restart=on-failure
User=ec2-user

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Reloading systemd and enabling Vault service..."
sudo systemctl daemon-reload
sudo systemctl enable vault
sudo systemctl start vault

echo "📊 Checking Vault status..."
vault status || true

echo "✅ Vault installation and service setup complete!"
