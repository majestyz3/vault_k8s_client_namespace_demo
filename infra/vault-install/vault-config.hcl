ui            = true
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}
storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-1"
}
api_addr = "http://0.0.0.0:8200"
cluster_addr = "https://0.0.0.0:8201"
seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "REPLACE_WITH_YOUR_KMS_KEY_ID"
}
license_path = "/etc/vault/vault.hclic"


