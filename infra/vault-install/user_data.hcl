#!/bin/bash
set -e

echo "Installing Vault version ${vault_version}"

# Install Vault
cd /tmp
curl -L -o vault.zip "https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip"
unzip vault.zip
sudo mv vault /usr/local/bin/vault
sudo chmod +x /usr/local/bin/vault

echo "Vault installed successfully"

# Write Vault configuration
cat <<EOF | sudo tee /etc/vault/vault.hcl
${vault_config}
EOF

# Write Vault license
cat <<EOF | sudo tee /etc/vault/vault.hclic
${vault_license}
EOF

# Enable and start Vault service (assumes systemd service exists in your install flow)
sudo systemctl enable vault
sudo systemctl start vault


