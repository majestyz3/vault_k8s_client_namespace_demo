#!/bin/bash
set -e

# Variables
SSH_KEY="vault-demo-key.pem"
AWS_REGION="us-east-1"
TF_DIR="infra"
VAULT_INSTALL_DIR="$TF_DIR/vault-install"

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
VAULT_AUTO_UNSEAL_KMS_KEY_ARN=$(terraform output -raw vault_auto_unseal_kms_key_arn)
VAULT_PRIVATE_IP=$(terraform output -raw vault_private_ip)

# ✅ Step 5 - Generate Vault Configuration
echo "🔧 Generating Vault configuration file..."
cat <<EOF > "$VAULT_INSTALL_DIR/vault-config.hcl"
ui = true

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-1"
}

api_addr     = "http://127.0.0.1:8200"
cluster_addr = "http://${VAULT_PRIVATE_IP}:8201"  

seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "${VAULT_AUTO_UNSEAL_KMS_KEY_ARN}"
}

license_path = "/etc/vault/vault.hclic"
EOF

# ✅ Step 6 - Validate Config File Exists
if [ ! -f "$VAULT_INSTALL_DIR/vault-config.hcl" ]; then
  echo "❌ ERROR: vault-config.hcl was not generated! Check Terraform execution."
  exit 1
fi

cd ..

# ✅ Step 7 - Wait for SSH Availability
echo "⏳ Waiting for SSH to be available..."
for i in {1..10}; do
  ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$VAULT_PUBLIC_IP" "echo 'SSH is ready'" && break
  echo "⏳ Retrying SSH connection... Attempt $i/10"
  sleep 10
done

# ✅ Step 8 - Upload Vault Files to EC2
echo "📂 Uploading necessary files to Vault instance ($VAULT_PUBLIC_IP)..."
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" "$VAULT_INSTALL_DIR/vault.hclic" ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/vault.hclic
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" "$VAULT_INSTALL_DIR/install_vault.sh" ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/install_vault.sh
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" "$VAULT_INSTALL_DIR/vault-config.hcl" ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/vault.hcl

# ✅ Step 9 - Install Vault & Configure Service
echo "🚀 Running Vault install script on EC2 instance..."
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$VAULT_PUBLIC_IP" 'chmod +x /home/ec2-user/install_vault.sh && sudo /home/ec2-user/install_vault.sh'

# ✅ Step 10 - Initialize & Unseal Vault
echo "🔑 Initializing and unsealing Vault..."
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$VAULT_PUBLIC_IP" <<'EOF'
export VAULT_ADDR="http://127.0.0.1:8200"

if [ ! -f /home/ec2-user/.vault_initialized ]; then
    echo "🔑 Initializing Vault..."
    vault operator init -format=json > /home/ec2-user/init.json
    jq -r '.unseal_keys_b64[]' /home/ec2-user/init.json > /home/ec2-user/unseal-keys.txt
    jq -r '.root_token' /home/ec2-user/init.json > /home/ec2-user/root-token.txt
    touch /home/ec2-user/.vault_initialized
fi

# ✅ Automatically Unseal Vault
echo "🔓 Unsealing Vault..."
UNSEAL_KEYS=$(cat /home/ec2-user/unseal-keys.txt)
for key in $UNSEAL_KEYS; do
    vault operator unseal "$key" || echo "⚠️ Failed to unseal with key: $key"
done
EOF


# ✅ Step 11 - Fetch Unseal KeLocalys & Root Token Back to 
echo "📥 Fetching Vault unseal keys and root token..."
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/unseal-keys.txt ./unseal-keys.txt
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$VAULT_PUBLIC_IP":/home/ec2-user/root-token.txt ./root-token.txt

# ✅ Step 12 - Save Outputs
echo "📄 Writing credentials to deployment-outputs.txt..."
cat <<EOF > deployment-outputs.txt
eks_cluster_endpoint = "$EKS_CLUSTER_ENDPOINT"
eks_cluster_ca = "$EKS_CLUSTER_CA"
vault_public_ip = "$VAULT_PUBLIC_IP"
vault_private_ip = "$VAULT_PRIVATE_IP"
vault_auto_unseal_kms_key_arn = "$VAULT_AUTO_UNSEAL_KMS_KEY_ARN"
vault_root_token = "$(cat root-token.txt)"
vault_unseal_keys = "$(cat unseal-keys.txt | tr '\n' ',' | sed 's/,$//')"

# 🚀 Access Vault UI:
http://$VAULT_PUBLIC_IP:8200

# 🖥️ SSH into Vault instance:
ssh -i "$SSH_KEY" ec2-user@$VAULT_PUBLIC_IP
EOF

echo "✅ All tasks completed successfully!"

