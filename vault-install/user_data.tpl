#!/bin/bash
set -e

sudo yum install -y unzip

VAULT_VERSION="${vault_version}"

# Install Vault
curl -O https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip
unzip vault_${vault_version}_linux_amd64.zip
sudo mv vault /usr/local/bin/

# Create Vault Config Directory
mkdir -p /etc/vault

# Add Vault Config (filled from template)
cat <<EOF > /etc/vault/vault.hcl
$(cat ${path.module}/vault-install/vault-config.tpl)
EOF

# Ensure License Exists
if [ ! -f /etc/vault/vault.hclic ]; then
    echo "Vault license file missing!" >&2
    exit 1
fi

# Create Vault Systemd Service
cat <<EOF > /etc/systemd/system/vault.service
[Unit]
Description=Vault Service
After=network.target

[Service]
ExecStart=/usr/local/bin/vault server -config=/etc/vault/vault.hcl
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Start Vault
sudo systemctl enable vault
sudo systemctl start vault

