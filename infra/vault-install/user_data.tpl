#!/bin/bash

# Write Vault License to file
cat <<EOF > /etc/vault/vault.hclic
${vault_license}
EOF

# Install dependencies
yum install -y jq unzip

# Install Vault
curl -fsSL https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip -o vault.zip
unzip vault.zip -d /usr/local/bin/
chmod +x /usr/local/bin/vault

# Create Vault config directory
mkdir -p /etc/vault

# Write Vault configuration file
cat <<EOT > /etc/vault/vault.hcl
${vault_config}
EOT

# Create a systemd service for Vault
cat <<EOT > /etc/systemd/system/vault.service
[Unit]
Description=Vault
Requires=network-online.target
After=network-online.target

[Service]
User=root
Group=root
ExecStart=/usr/local/bin/vault server -config=/etc/vault/vault.hcl
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOT

# Enable and start Vault service
systemctl enable vault
systemctl start vault

# Optional: Add Vault to PATH (for convenience if you SSH in)
echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bashrc


