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
cluster_addr = "http://10.0.1.217:8201"  

seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "arn:aws:kms:us-east-1:656794478190:key/46c4ab07-d784-452b-bc1a-734d455ba0c8"
}

license_path = "/etc/vault/vault.hclic"
