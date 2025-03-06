#!/bin/bash
set -e

VAULT_ADDR=$1
VAULT_TOKEN_PATH="vault-keys.json"

echo "Checking Vault initialization status at $VAULT_ADDR..."

if curl -s "${VAULT_ADDR}/v1/sys/health" | grep '"initialized":false'; then
    echo "Initializing Vault..."
    vault operator init -format=json | tee "${VAULT_TOKEN_PATH}"
else
    echo "Vault already initialized, retrieving keys (if they exist)."
    if [ ! -f "${VAULT_TOKEN_PATH}" ]; then
        echo "Error: Vault is initialized but keys file is missing! You may need to manually recover."
        exit 1
    fi
fi

echo "Unsealing Vault using 3 keys..."
for i in $(seq 0 2); do
    key=$(jq -r ".unseal_keys_b64[$i]" "${VAULT_TOKEN_PATH}")
    vault operator unseal $key
done

vault status

# Output keys and root token for convenience (can be captured into Terraform outputs if needed)
echo "Unseal Keys:"
jq '.unseal_keys_b64' "${VAULT_TOKEN_PATH}"

echo "Root Token:"
jq -r '.root_token' "${VAULT_TOKEN_PATH}"

