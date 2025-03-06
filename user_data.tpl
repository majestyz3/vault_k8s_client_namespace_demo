#!/bin/bash
set -e

# Install Vault
yum install -y unzip
curl -o /tmp/vault.zip https://releases.hashicorp.com/vault/1.15.0/vault_1.15.0_linux_amd64.zip
unzip /tmp/vault.zip -d /usr/local/bin/

# Write Config
mkdir -p /etc/vault
cat <<EOF > /etc/vault/vault.hcl
${vault_config}
EOF

# Create Systemd Service
cat <<EOF > /etc/systemd/system/vault.service
[Unit]
Description=Vault
After=network.target

[Service]
ExecStart=/usr/local/bin/vault server -config=/etc/vault/vault.hcl
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start Vault
systemctl enable vault
systemctl start vault
