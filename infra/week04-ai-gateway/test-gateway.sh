#!/usr/bin/env bash
# Week 4: test the AI gateway from your laptop.
# Usage: RG=<resource group> ./test-gateway.sh   (make week4-test does this)
set -u
RG=${RG:?set RG}
APIM=$(az apim list -g "$RG" --query "[0].name" -o tsv)
FOUNDRY=$(az cognitiveservices account list -g "$RG" --query "[0].name" -o tsv)
GW="https://${APIM}.azure-api.net/ai/openai/v1"
SUB_ID=$(az account show --query id -o tsv)
KEY=$(az rest --method post \
  --url "https://management.azure.com/subscriptions/${SUB_ID}/resourceGroups/${RG}/providers/Microsoft.ApiManagement/service/${APIM}/subscriptions/retail-banking-app/listSecrets?api-version=2024-05-01" \
  --query primaryKey -o tsv)
pass=0; fail=0
check() { if [ "$2" = "$3" ]; then echo "PASS  $1"; pass=$((pass+1)); else echo "FAIL  $1 (expected $3, got $2)"; fail=$((fail+1)); fi; }
chat() { curl -s -o /tmp/gw-body.json -D /tmp/gw-headers.txt -w '%{http_code}' "$GW/chat/completions" -H "Content-Type: application/json" "$@"; }
body() { echo "{\"model\":\"gpt-4.1-mini\",\"max_tokens\":$1,\"messages\":[{\"role\":\"user\",\"content\":\"$2\"}]}"; }

check "no subscription key is refused (401)" "$(chat -d "$(body 20 hi)")" "401"
check "app key works (200)"                  "$(chat -H "api-key: $KEY" -d "$(body 40 'What does a bank AI gateway do? One sentence.')")" "200"
python3 -c 'import json;print("      answer:", json.load(open("/tmp/gw-body.json"))["choices"][0]["message"]["content"])' 2>/dev/null
grep -i "x-remaining-tokens" /tmp/gw-headers.txt | sed 's/^/      /'

echo "      sending large requests until the token limit kicks in..."
code=""
for i in $(seq 1 8); do
  code=$(chat -H "api-key: $KEY" -d "$(body 1500 'Write a long, detailed essay about the history of Canadian banking.')")
  [ "$code" = "429" ] && break
done
check "token limit returns 429"               "$code" "429"
grep -i "retry-after" /tmp/gw-headers.txt | sed 's/^/      /'

direct=$(curl -s -o /dev/null -w '%{http_code}' "https://${FOUNDRY}.openai.azure.com/openai/v1/models" -H "Authorization: Bearer $(az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv)")
check "Foundry is NOT reachable directly from the internet (403)" "$direct" "403"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
