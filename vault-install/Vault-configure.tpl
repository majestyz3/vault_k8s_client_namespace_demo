storage "s3" {
  bucket = "vault-data-bucket"
  region = "${region}"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

ui = true

license_path = "/etc/vault/vault.hclic"
