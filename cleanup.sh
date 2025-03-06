#!/bin/bash
set -e

VAULT_ADDR=$1

if [ -z "$VAULT_ADDR" ]; then
    echo "Usage: ./cleanup.sh <VAULT_ADDR>"
    exit 1
fi

# Re-seal before destroy (optional)
vault operator seal || true

# Wipe all entities, aliases, policies, auth methods
for entity in $(vault list -format=json identity/entity/id | jq -r '.[]'); do
    vault delete identity/entity/id/$entity
done

for alias in $(vault list -format=json identity/entity-alias/id | jq -r '.[]'); do
    vault delete identity/entity-alias/id/$alias
done

for auth in $(vault auth list -format=json | jq -r 'keys[]' | grep -v 'token/'); do
    vault auth disable $auth
done

for policy in $(vault policy list -format=json | jq -r '.[]' | grep -vE '^(root|default)$'); do
    vault policy delete $policy
done

echo "Cleanup complete."
