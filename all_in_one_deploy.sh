#!/bin/bash
set -e

# Variables
SSH_KEY="vault-demo-key.pem"
AWS_REGION="us-east-1"
TF_DIR="infra"

# ✅ Step 1 - Retrieve latest credentials from Doormat
echo "🔑 Retrieving fresh credentials from Doormat..."
doormat aws export --account aws_majid.zarkesh_test
echo "✅ AWS credentials retrieved and exported to environment."

# ✅ Step 2 - Set Region (recommended to explicitly set)
export AWS_REGION="$AWS_REGION"
echo "🌍 AWS_REGION set to: $AWS_REGION"

# ✅ Step 3 - Terraform Init & Apply
cd "$TF_DIR"
echo "⚙️ Running terraform init..."
terraform init

echo "✅ Running terraform apply..."
terraform apply -auto-approve

# ✅ Step 4 - Capture Outputs
VAULT_PUBLIC_IP=$(terraform output -raw vault_public_ip)
EKS_CLUSTER_ENDPOINT=$(terraform output -raw eks_cluster_endpoint)
EKS_CLUSTER_CA=$(terraform output -raw eks_cluster_ca)

echo "📄 Capturing outputs to deployment-outputs.txt..."
cat <<EOF > ../deployment-outputs.txt
eks_cluster_endpoint = "$EKS_CLUSTER_ENDPOINT"
eks_cluster_ca = "$EKS_CLUSTER_CA"
vault_public_ip = "$VAULT_PUBLIC_IP"
EOF

cd ..

# ✅ Step 5 - Upload Vault Files to EC2
echo "📂 Uploading necessary files to EC2 instance ($VAULT_PUBLIC_IP)..."

scp -o StrictHostKeyChecking=no -i "$SSH_KEY" "infra/vault-install/vault.hclic" ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/vault.hclic
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" "infra/vault-install/install_vault.sh" ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/install_vault.sh
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" "infra/vault-install/vault-config.hcl" ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/vault-config.hcl

# ✅ Step 6 - Install Vault & Configure Service
echo "🚀 Running Vault install script on EC2 instance..."
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$VAULT_PUBLIC_IP" 'chmod +x /home/ec2-user/install_vault.sh && sudo /home/ec2-user/install_vault.sh'

# ✅ Step 7 - Initialize & Unseal Vault
echo "🔑 Initializing and unsealing Vault..."
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$VAULT_PUBLIC_IP" <<'EOF'
export VAULT_ADDR="http://127.0.0.1:8200"
if [ ! -f /home/ec2-user/.vault_initialized ]; then
    vault operator init -format=json > /home/ec2-user/init.json
    jq -r '.unseal_keys_b64[]' /home/ec2-user/init.json > /home/ec2-user/unseal-keys.txt
    jq -r '.root_token' /home/ec2-user/init.json > /home/ec2-user/root-token.txt
    touch /home/ec2-user/.vault_initialized
fi

UNSEAL_KEYS=$(cat /home/ec2-user/unseal-keys.txt)
for key in $UNSEAL_KEYS; do
    vault operator unseal "$key"
done
EOF

# ✅ Step 8 - Fetch Unseal Keys & Root Token Back to Local
echo "📥 Fetching Vault unseal keys and root token..."
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/unseal-keys.txt ./unseal-keys.txt
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/root-token.txt ./root-token.txt

cat <<EOF >> deployment-outputs.txt
Vault Unseal Keys:
$(cat unseal-keys.txt)

Vault Root Token:
$(cat root-token.txt)
EOF

echo "✅ All tasks completed successfully!"
