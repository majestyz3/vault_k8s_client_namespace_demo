output "unseal_keys" {
  value = fileexists("${path.module}/vault-keys.json") ? jsondecode(file("${path.module}/vault-keys.json")).unseal_keys_b64 : null
  sensitive = true
}

output "root_token" {
  value = fileexists("${path.module}/vault-keys.json") ? jsondecode(file("${path.module}/vault-keys.json")).root_token : null
  sensitive = true
}