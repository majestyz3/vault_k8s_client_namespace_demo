ui = true

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-1"
}

api_addr     = "http://0.0.0.0:8200"
cluster_addr = "http://${PRIVATE_IP}:8201"  # Ensure PRIVATE_IP is correctly substituted

seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "${KMS_KEY_ID}"  # Ensure Terraform replaces this correctly
}

license_path = "/etc/vault/vault.hclic"


