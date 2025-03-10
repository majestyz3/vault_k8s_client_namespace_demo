#!/bin/bash
set -e

# Variables
SSH_KEY="vault-demo-key.pem"
AWS_REGION="us-east-1"
TF_DIR="infra"

# ✅ Step 1 - Retrieve Local IP for Security
LOCAL_IP=$(curl -s https://checkip.amazonaws.com)/32
echo "🔍 Detected Local IP: $LOCAL_IP"
echo "✅ Restricting SSH access to this IP."

# ✅ Step 2 - Retrieve latest credentials from Doormat
echo "🔑 Retrieving fresh credentials from Doormat..."
doormat aws export --account aws_majid.zarkesh_test
echo "✅ AWS credentials retrieved and exported to environment."

# ✅ Step 3 - Set Region
export AWS_REGION="$AWS_REGION"
echo "🌍 AWS_REGION set to: $AWS_REGION"

# ✅ Step 4 - Terraform Init & Apply
cd "$TF_DIR"
echo "⚙️ Running terraform init..."
terraform init

echo "✅ Running terraform apply..."
terraform apply -auto-approve -var "allowed_ssh_ip=$LOCAL_IP"

# ✅ Step 5 - Capture Outputs
VAULT_PUBLIC_IP=$(terraform output -raw vault_public_ip)
VAULT_DR_PUBLIC_IP=$(terraform output -raw vault_dr_public_ip)
EKS_CLUSTER_ENDPOINT=$(terraform output -raw eks_cluster_endpoint)
EKS_CLUSTER_CA=$(terraform output -raw eks_cluster_ca)
VAULT_AUTO_UNSEAL_KMS_KEY_ARN=$(terraform output -raw vault_auto_unseal_kms_key_arn)

cd ..

# ✅ Step 6 - Upload Vault Files to EC2 (Primary Vault)
echo "📂 Uploading necessary files to Primary Vault instance ($VAULT_PUBLIC_IP)..."
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" infra/vault-install/install_vault.sh ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/install_vault.sh
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" infra/vault-install/vault-config-primary.hcl ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/vault.hcl
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" infra/vault-install/user_data_primary.tpl ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/user_data.tpl
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" infra/vault-install/vault.hclic ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/vault.hclic

# ✅ Step 7 - Upload Vault Files to EC2 (DR Vault)
echo "📂 Uploading necessary files to DR Vault instance ($VAULT_DR_PUBLIC_IP)..."
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" infra/vault-install/install_vault.sh ec2-user@"$VAULT_DR_PUBLIC_IP":/home/ec2-user/install_vault.sh
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" infra/vault-install/vault-config-dr.hcl ec2-user@"$VAULT_DR_PUBLIC_IP":/home/ec2-user/vault.hcl
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" infra/vault-install/user_data_dr.tpl ec2-user@"$VAULT_DR_PUBLIC_IP":/home/ec2-user/user_data.tpl
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" infra/vault-install/vault.hclic ec2-user@"$VAULT_DR_PUBLIC_IP":/home/ec2-user/vault.hclic

# ✅ Step 8 - Install Vault & Configure Service (Primary Vault)
echo "🚀 Running Vault install script on Primary Vault instance..."
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$VAULT_PUBLIC_IP" \
  "chmod +x /home/ec2-user/install_vault.sh && sudo /home/ec2-user/install_vault.sh 1.19.0 '$(cat infra/vault-install/vault.hclic)' '$VAULT_AUTO_UNSEAL_KMS_KEY_ARN' false"

# ✅ Step 9 - Install Vault & Configure Service (DR Vault)
echo "🚀 Running Vault install script on DR Vault instance..."
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$VAULT_DR_PUBLIC_IP" \
  "chmod +x /home/ec2-user/install_vault.sh && sudo /home/ec2-user/install_vault.sh 1.19.0 '$(cat infra/vault-install/vault.hclic)' '$VAULT_AUTO_UNSEAL_KMS_KEY_ARN' true 'http://$VAULT_PUBLIC_IP:8200'"

# ✅ Step 10 - Append SSH Commands to `deployment-outputs.txt`
echo "📄 Writing credentials and connection details to deployment-outputs.txt..."
cat <<EOF > deployment-outputs.txt
#############################################
#         🚀 Vault Deployment Info         #
#############################################

# ✅ AWS EKS Cluster Details
eks_cluster_endpoint = "$EKS_CLUSTER_ENDPOINT"
eks_cluster_ca = "$EKS_CLUSTER_CA"

# ✅ Vault Primary Server
vault_public_ip = "$VAULT_PUBLIC_IP"
vault_address = "http://$VAULT_PUBLIC_IP:8200"

# ✅ Vault Disaster Recovery (DR) Server
vault_dr_public_ip = "$VAULT_DR_PUBLIC_IP"
vault_dr_address = "http://$VAULT_DR_PUBLIC_IP:8200"

# ✅ Vault KMS Auto-Unseal
vault_auto_unseal_kms_key_arn = "$VAULT_AUTO_UNSEAL_KMS_KEY_ARN"

#############################################
#          🔑 Access Instructions          #
#############################################

# ✅ Connect to Primary Vault via SSH
ssh -i "$SSH_KEY" ec2-user@"$VAULT_PUBLIC_IP"

# ✅ Connect to DR Vault via SSH
ssh -i "$SSH_KEY" ec2-user@"$VAULT_DR_PUBLIC_IP"

# ✅ Open Vault UI (Primary)
echo "Open http://$VAULT_PUBLIC_IP:8200 in your browser"

# ✅ Open Vault UI (DR)
echo "Open http://$VAULT_DR_PUBLIC_IP:8200 in your browser"

EOF

echo "✅ All tasks completed successfully!"
