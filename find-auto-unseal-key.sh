#!/bin/bash

# List of Key IDs
keys=(
    "3e172e37-8229-4a24-b02a-1fc8cceb65df"
    "4e62e3c5-aa65-4900-a414-5915d0e1d769"
    "6a24712e-99c1-46d0-883e-c879144c2a7d"
    "6a4c6ace-ae8f-4e4b-9a73-40ae183e60f3"
    "97f1ab43-b23d-474d-9990-f0b3789ece19"
    "a9aeeb2d-ffc9-430c-bf95-415e39b25798"
    "cb01c081-9c7d-4489-a5f5-4d30493366db"
    "eb086d1b-bc44-4d01-9550-359b28e9b23d"
)

# Region (update if needed)
region="us-east-1"

echo "🔎 Searching for KMS key with 'Auto-Unseal' or 'auto-unseal' in description or tags..."

for key in "${keys[@]}"; do
    # Describe the key (for description field)
    description=$(aws kms describe-key --key-id "$key" --region "$region" --query 'KeyMetadata.Description' --output text)

    if echo "$description" | grep -E -i "Auto-Unseal|auto-unseal" >/dev/null; then
        echo "✅ Found match in description for Key: $key"
        echo "Description: $description"
        exit 0
    fi

    # List tags and check for 'Auto-Unseal' or 'auto-unseal' in tags
    tags=$(aws kms list-resource-tags --key-id "$key" --region "$region" --query 'Tags[*].Value' --output text)

    if echo "$tags" | grep -E -i "Auto-Unseal|auto-unseal" >/dev/null; then
        echo "✅ Found match in tags for Key: $key"
        echo "Tags: $tags"
        exit 0
    fi
done

echo "❌ No matching KMS key with 'Auto-Unseal' or 'auto-unseal' found."