storage "s3" {
  bucket = "${aws_s3_bucket.vault_backend.bucket}"
  region = "${var.aws_region}"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

ui = true

cluster_name = "${var.vault_cluster_name}"

api_addr = "http://0.0.0.0:8200"
