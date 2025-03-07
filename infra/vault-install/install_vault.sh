#!/bin/bash
set -euo pipefail

echo "🚀 Installing Vault Enterprise 1.19.0..."

# Update and install dependencies
sudo yum update -y
sudo yum install -y unzip jq

# Download and install Vault
VAULT_VERSION="1.19.0+ent"
VAULT_ZIP="vault_${VAULT_VERSION}_linux_amd64.zip"

curl -o /tmp/vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_ZIP}"
sudo unzip -o /tmp/vault.zip -d /usr/local/bin/
sudo chmod +x /usr/local/bin/vault

vault --version

# Create Vault user and directories
sudo useradd --system --home /etc/vault.d --shell /bin/false vault || true
sudo mkdir -p /opt/vault/data
sudo mkdir -p /etc/vault.d
sudo mkdir -p /etc/vault

# Copy the configuration file and license (assumes they are SCP'd beforehand)
sudo mv /home/ec2-user/vault-config.hcl /etc/vault.d/vault.hcl
sudo mv /home/ec2-user/vault.hclic /etc/vault/vault.hclic
sudo chown -R vault:vault /opt/vault /etc/vault /etc/vault.d

# Create Vault systemd service
cat <<EOF | sudo tee /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Requires=network-online.target
After=network-online.target

[Service]
User=vault
Group=vault
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP \$MAINPID
KillSignal=SIGTERM
Restart=on-failure
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Vault service
sudo systemctl daemon-reload
sudo systemctl enable vault
sudo systemctl start vault
sudo systemctl status vault --no-pager

# Final confirmation of Vault status
sleep 5
vault status || sudo journalctl -u vault --no-pager
