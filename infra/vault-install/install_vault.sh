#!/bin/bash

set -e

# Variables
VAULT_VERSION="1.16.0+ent"
VAULT_LICENSE_PATH="/etc/vault/vault.hclic"
INIT_FILE="/etc/vault/vault-init.json"
UNSEAL_KEYS_FILE="/etc/vault/unseal-keys.txt"
ROOT_TOKEN_FILE="/etc/vault/root-token.txt"
OUTPUTS_FILE="/etc/vault/vault-outputs.txt"

# Install Vault
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install -y vault jq

# Create Config Directory
sudo mkdir -p /etc/vault /opt/vault/data

# Move License File
sudo mv ~/vault.hclic $VAULT_LICENSE_PATH
sudo chmod 600 $VAULT_LICENSE_PATH

# Write Vault Config
sudo tee /etc/vault/vault.hcl > /dev/null <<EOT
ui = true
disable_mlock = true

storage "file" {
  path = "/opt/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

license_path = "$VAULT_LICENSE_PATH"
EOT

# Create Systemd Service
sudo tee /etc/systemd/system/vault.service > /dev/null <<EOT
[Unit]
Description=Vault - A tool for managing secrets
Requires=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/vault server -config=/etc/vault/vault.hcl
Restart=on-failure
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOT

# Start Vault Service
sudo systemctl daemon-reload
sudo systemctl enable vault
sudo systemctl start vault

# Wait for Vault to start
sleep 10

# Init and Unseal (only if not already initialized)
if [ ! -f $INIT_FILE ]; then
    export VAULT_ADDR="http://127.0.0.1:8200"

    vault operator init -format=json | sudo tee $INIT_FILE

    jq -r '.unseal_keys_b64[]' $INIT_FILE | sudo tee $UNSEAL_KEYS_FILE
    jq -r '.root_token' $INIT_FILE | sudo tee $ROOT_TOKEN_FILE

    vault operator unseal $(head -n 1 $UNSEAL_KEYS_FILE)
    vault operator unseal $(sed -n '2p' $UNSEAL_KEYS_FILE)
    vault operator unseal $(sed -n '3p' $UNSEAL_KEYS_FILE)

    echo 'export VAULT_ADDR="http://127.0.0.1:8200"' | sudo tee -a /etc/profile
    echo 'export VAULT_ADDR="http://127.0.0.1:8200"' >> ~/.bashrc
fi

# Generate Outputs File
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

sudo tee $OUTPUTS_FILE > /dev/null <<EOT
Vault Public IP: $PUBLIC_IP
Vault Unseal Keys:
$(cat $UNSEAL_KEYS_FILE)

Vault Root Token:
$(cat $ROOT_TOKEN_FILE)

Vault UI URL: http://$PUBLIC_IP:8200
EOT

echo "✅ Vault installation, initialization, and unseal complete!"
echo "📄 Vault outputs saved to $OUTPUTS_FILE"
