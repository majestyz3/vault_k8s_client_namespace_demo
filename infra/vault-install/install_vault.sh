#!/bin/bash
set -e

echo "🚀 Starting All-In-One Deployment for Vault + EKS Demo"

# ------------------------------------------------------------------------------
# Step 1 - Check if Doormat Credential Server is running
# ------------------------------------------------------------------------------
if ! curl -s http://127.0.0.1:9000 > /dev/null; then
    echo "❌ Doormat Credential Server is not running. Please run 'doormat cred-server' in a separate terminal."
    exit 1
else
    echo "✅ Doormat Credential Server is already running."
fi

# Set necessary environment variables for Terraform
export AWS_CONTAINER_CREDENTIALS_FULL_URI="http://127.0.0.1:9000/role/aws_majid.zarkesh_test"
export AWS_REGION="us-east-1"

echo "🔗 AWS_CONTAINER_CREDENTIALS_FULL_URI set to: $AWS_CONTAINER_CREDENTIALS_FULL_URI"
echo "🌍 AWS_REGION set to: $AWS_REGION"

# ------------------------------------------------------------------------------
# Step 2 - Terraform Init and Apply for Infrastructure
# ------------------------------------------------------------------------------
echo "⚙️ Running terraform init..."
cd infra
terraform init

echo "✅ Running terraform apply..."
terraform apply -auto-approve

# Capture outputs into variables
eks_cluster_ca=$(terraform output -raw eks_cluster_ca)
eks_cluster_endpoint=$(terraform output -raw eks_cluster_endpoint)
vault_public_ip=$(terraform output -raw vault_public_ip)

# Save to deployment-outputs.txt
cat <<EOF > ../deployment-outputs.txt
eks_cluster_ca = "$eks_cluster_ca"
eks_cluster_endpoint = "$eks_cluster_endpoint"
vault_public_ip = "$vault_public_ip"
EOF

echo "📄 Outputs saved to deployment-outputs.txt"

# ------------------------------------------------------------------------------
# Step 3 - SCP Files to EC2 Instance
# ------------------------------------------------------------------------------
echo "📂 Copying Vault install script, license file, and key to Vault instance"

scp -o StrictHostKeyChecking=no -i ../vault-demo-key.pem vault-install/install_vault.sh ec2-user@$vault_public_ip:/home/ec2-user/
scp -o StrictHostKeyChecking=no -i ../vault-demo-key.pem vault-install/vault.hclic ec2-user@$vault_public_ip:/home/ec2-user/

# ------------------------------------------------------------------------------
# Step 4 - SSH into EC2 and Run Install Script
# ------------------------------------------------------------------------------
echo "💻 Running Vault installation and initialization script remotely"

ssh -o StrictHostKeyChecking=no -i ../vault-demo-key.pem ec2-user@$vault_public_ip "chmod +x /home/ec2-user/install_vault.sh && sudo /home/ec2-user/install_vault.sh"

# ------------------------------------------------------------------------------
# Step 5 - Retrieve Vault Init Output and Store Locally
# ------------------------------------------------------------------------------
scp -o StrictHostKeyChecking=no -i ../vault-demo-key.pem ec2-user@$vault_public_ip:/home/ec2-user/vault-init-output.json ../vault-init-output.json

echo "✅ Vault initialized, and init output saved to vault-init-output.json"

echo "🎉 Deployment completed successfully!"

