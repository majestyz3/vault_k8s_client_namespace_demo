variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_session_token" {}

variable "ssh_private_key" {
  default = "../vault-demo-key.pem"
}