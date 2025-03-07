#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

echo "✅ Checking if Doormat Credential Server is running..."
if pgrep -f "doormat cred-server" > /dev/null; then
    echo "✅ Doormat Credential Server is already running."
else
    echo "🚀 Starting Doormat Credential Server..."
    doormat cred-server &
    sleep 5  # Give it time to start
fi

export AWS_CONTAINER_CREDENTIALS_FULL_URI="http://127.0.0.1:9000/role/aws_majid.zarkesh_test"
export AWS_REGION="us-east-1"
echo "🔗 AWS_CONTAINER_CREDENTIALS_FULL_URI set to: $AWS_CONTAINER_CREDENTIALS_FULL_URI"
echo "🌍 AWS_REGION set to: $AWS_REGION"

echo "⚙️ Running terraform init..."
terraform -chdir=infra init

echo "✅ Running terraform apply..."
terraform -chdir=infra apply -auto-approve

# Fetch Vault Public IP
VAULT_PUBLIC_IP=$(terraform -chdir=infra output -raw vault_public_ip)

if [ -z "$VAULT_PUBLIC_IP" ]; then
    echo "❌ Error: Vault public IP not found!"
    exit 1
fi

echo "🔗 Vault Public IP: $VAULT_PUBLIC_IP"

# Secure Copy Files to Vault Instance
echo "📤 Copying necessary files to Vault instance..."
scp -o StrictHostKeyChecking=no -i vault-demo-key.pem \
    vault.hclic \
    vault-install/install_vault.sh \
    ec2-user@$VAULT_PUBLIC_IP:/home/ec2-user/

# Run Vault Installation Script on Remote Instance
echo "🚀 Installing Vault on EC2 Instance..."
ssh -o StrictHostKeyChecking=no -i vault-demo-key.pem ec2-user@$VAULT_PUBLIC_IP "chmod +x /home/ec2-user/install_vault.sh && sudo /home/ec2-user/install_vault.sh"

# Initialize Vault
echo "🔑 Initializing Vault..."
ssh -o StrictHostKeyChecking=no -i vault-demo-key.pem ec2-user@$VAULT_PUBLIC_IP "vault operator init -format=json | tee /home/ec2-user/init.json"

# Retrieve Init File
scp -o StrictHostKeyChecking=no -i vault-demo-key.pem ec2-user@$VAULT_PUBLIC_IP:/home/ec2-user/init.json ./init.json

# Extract Unseal Keys & Root Token
jq -r '.unseal_keys_b64[]' init.json > unseal-keys.txt
jq -r '.root_token' init.json > root-token.txt

# Display outputs
echo "📄 Vault initialized successfully! Unseal keys and root token saved."

echo "🎉 Deployment completed successfully!"


