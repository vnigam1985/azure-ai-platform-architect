#!/usr/bin/env bash
# Runs ON the test VM (make week2-test sends it with `az vm run-command invoke`).
# Proves three things:
#   1. The Foundry name resolves to a PRIVATE IP inside the VNet
#   2. The VM gets an Entra ID token from its managed identity (no keys anywhere)
#   3. The model answers through the private endpoint
# Inputs (set by the Makefile): FOUNDRY_NAME, CLIENT_ID, MODEL
set -u
HOST="${FOUNDRY_NAME}.openai.azure.com"

echo "== 1. DNS =="
IP=$(getent hosts "$HOST" | awk '{print $1}')
echo "$HOST -> ${IP:-no answer}"
case "$IP" in
  10.*) echo "PASS private IP" ;;
  *)    echo "FAIL expected a 10.x address. Check the DNS zone links (week 1) and the DNS zone group (week 2)" ;;
esac

echo "== 2. Token from managed identity =="
TOKEN=$(curl -s -H "Metadata: true" \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://cognitiveservices.azure.com&client_id=${CLIENT_ID}" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin).get("access_token",""))')
[ -n "$TOKEN" ] && echo "PASS got a token (${#TOKEN} chars)" || echo "FAIL no token"

echo "== 3. Call the model over the private endpoint =="
curl -s -w '\nHTTP %{http_code}\n' "https://${HOST}/openai/v1/chat/completions" \
  -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" \
  -d "{\"model\":\"${MODEL}\",\"max_tokens\":40,\"messages\":[{\"role\":\"user\",\"content\":\"Say hello from a private endpoint in one short sentence.\"}]}" \
  | python3 -c '
import json, sys
raw = sys.stdin.read(); body, _, status = raw.rpartition("\nHTTP ")
print("HTTP", status.strip())
try:
    print("Answer:", json.loads(body)["choices"][0]["message"]["content"])
except Exception:
    print(body[:400])
'
