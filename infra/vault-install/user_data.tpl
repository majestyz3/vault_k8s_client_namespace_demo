#!/bin/bash
set -e

sudo yum install -y jq unzip

curl -L https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip -o vault.zip
unzip vault.zip
sudo mv vault /usr/local/bin/
sudo mkdir -p /etc/vault
echo '${vault_config}' | sudo tee /etc/vault/config.hcl

sudo tee /etc/systemd/system/vault.service <<EOF
[Unit]
Description=Vault service
After=network.target

[Service]
ExecStart=/usr/local/bin/vault server -config=/etc/vault/config.hcl
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable vault
sudo systemctl start vault

