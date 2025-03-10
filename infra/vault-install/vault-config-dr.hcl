ui = true

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "dr-vault"
}

api_addr = "http://0.0.0.0:8200"
cluster_addr = "https://0.0.0.0:8201"

replication {
  performance_secondary = true
  primary_api_addr      = "http://${aws_instance.vault.public_ip}:8200"
}

seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "${aws_kms_key.vault_auto_unseal.id}"
}

license_path = "/etc/vault/vault.hclic"
