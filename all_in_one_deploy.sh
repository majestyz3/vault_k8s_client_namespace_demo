#!/bin/bash

set -e

echo "🚀 Starting All-in-One Deployment for Vault on EKS"

# Step 1: Set AWS Region (Optional, since this is now in your variables.tf)
export AWS_REGION="us-east-1"

# Step 2: Run Terraform Init
echo "⚙️ Running terraform init in infra..."
cd infra
terraform init

# Step 3: Apply Infrastructure (VPC, EKS, Vault EC2)
echo "✅ Running terraform apply for infrastructure..."
terraform apply -auto-approve

# Step 4: Extract Outputs (EKS Cluster & Vault Public IP)
echo "📤 Fetching deployment outputs..."
eks_cluster_endpoint=$(terraform output -raw eks_cluster_endpoint)
eks_cluster_ca=$(terraform output -raw eks_cluster_ca)
vault_public_ip=$(terraform output -raw vault_public_ip)

# Step 5: Copy install script and Vault license to the Vault instance
echo "📦 Copying install script and license to Vault EC2 instance..."
scp -o StrictHostKeyChecking=no -i ../vault-demo-key.pem \
    ../infra/vault-install/install_vault.sh \
    ../infra/vault-install/vault.hclic \
    ec2-user@${vault_public_ip}:/home/ec2-user/

# Step 6: Execute Vault installation script on the EC2 instance
echo "⚙️ Running Vault installation script on EC2 instance..."
ssh -o StrictHostKeyChecking=no -i ../vault-demo-key.pem ec2-user@${vault_public_ip} "sudo bash /home/ec2-user/install_vault.sh"

# Step 7: Initialize Vault and capture Unseal Keys & Root Token
echo "🔑 Initializing Vault..."
ssh -o StrictHostKeyChecking=no -i ../vault-demo-key.pem ec2-user@${vault_public_ip} 'vault operator init -format=json | tee /home/ec2-user/vault-init.json'

# Step 8: Pull Unseal Keys & Root Token to local machine
echo "📥 Fetching unseal keys and root token..."
scp -o StrictHostKeyChecking=no -i ../vault-demo-key.pem ec2-user@${vault_public_ip}:/home/ec2-user/vault-init.json ../vault-init.json

# Extract and store them in deployment-outputs.txt
unseal_keys=$(jq -r '.unseal_keys_b64 | join(", ")' ../vault-init.json)
root_token=$(jq -r '.root_token' ../vault-init.json)

# Step 9: Save everything into deployment-outputs.txt
cat <<EOF > ../deployment-outputs.txt
eks_cluster_endpoint = "$eks_cluster_endpoint"
eks_cluster_ca = "$eks_cluster_ca"
vault_public_ip = "$vault_public_ip"
unseal_keys = "$unseal_keys"
root_token = "$root_token"
EOF

echo "📄 Outputs saved to deployment-outputs.txt"

# Step 10: Configure Kubernetes access (this is optional and could be moved to configure phase)
echo "🔗 Configuring kubectl for EKS cluster..."
aws eks update-kubeconfig --region $AWS_REGION --name vault-demo-cluster

echo "🎉 Deployment completed successfully!"
cd ..
