#!/bin/bash
set -e

# Install Vault
sudo yum install -y yum-utils shadow-utils jq
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install vault-${vault_version}

# Setup Vault Config
sudo mkdir -p /etc/vault/
sudo tee /etc/vault/vault.hcl <<EOF
${vault_config}
EOF

# Write Vault License
cat <<EOT > /etc/vault/vault.hclic
${vault_license}
EOT

# Start Vault
sudo systemctl enable vault
sudo systemctl start vault


