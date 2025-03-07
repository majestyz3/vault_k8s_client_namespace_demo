#!/bin/bash
set -e

# Install necessary tools
sudo yum install -y jq unzip

# Download and install Vault
VAULT_VERSION="1.19.0+ent"
VAULT_ZIP="vault_${VAULT_VERSION}_linux_amd64.zip"

curl -o /tmp/vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_ZIP}"
sudo unzip -o /tmp/vault.zip -d /usr/local/bin/
sudo chmod +x /usr/local/bin/vault

# Place license file into expected location
sudo mkdir -p /etc/vault
sudo mv /home/ec2-user/vault.hclic /etc/vault/vault.hclic

# Configure Vault systemd service
sudo tee /etc/systemd/system/vault.service > /dev/null <<EOF
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
User=vault
Group=vault
ExecStart=/usr/local/bin/vault server -config=/etc/vault/vault-config.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
Restart=on-failure
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

# Ensure Vault config file is correctly placed
sudo mv /home/ec2-user/vault-config.hcl /etc/vault/vault-config.hcl

# Set permissions
sudo chown -R vault:vault /etc/vault
sudo chmod 640 /etc/vault/vault-config.hcl

# Enable and start Vault service
sudo systemctl enable vault
sudo systemctl start vault


