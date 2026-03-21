#!/usr/bin/env bash

# script to deploy the APEX domain to Cloudflare with CNAME flattening

set -euo pipefail

ZONE_ID="${CF_ZONE_ID:?}"
TOKEN="${CF_API_TOKEN:?}"
TARGET="website-e7n.pages.dev"

EXISTING=$(curl -s \
  "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=CNAME&name=@" \
  -H "Authorization: Bearer ${TOKEN}" \
  | jq -r '.result[0] // empty')

EXISTING_CONTENT=$(echo "$EXISTING" | jq -r '.content // empty')
EXISTING_ID=$(echo "$EXISTING" | jq -r '.id // empty')

if [[ "$EXISTING_CONTENT" == "$TARGET" ]]; then
  echo "Apex CNAME unchanged, skipping."
  exit 0
fi

if [[ -z "$EXISTING_ID" ]]; then
  echo "No apex CNAME found, creating..."
  METHOD="POST"
  URL="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records"
else
  echo "Apex CNAME changed ($EXISTING_CONTENT → $TARGET), updating..."
  METHOD="PUT"
  URL="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${EXISTING_ID}"
fi

curl -s -X "$METHOD" "$URL" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{
    \"type\": \"CNAME\",
    \"name\": \"@\",
    \"content\": \"${TARGET}\",
    \"proxied\": true
  }" | jq -e '.success'