#!/usr/bin/env bash
# Runs ON the test VM (make week5-test sends it with `az vm run-command invoke`).
# The app is only reachable from inside the VNet, so we test from the VM.
# Input: APP_FQDN
set -u
URL="https://${APP_FQDN}"
echo "== DNS =="; getent hosts "$APP_FQDN" || echo "FAIL no DNS answer (check the private DNS zone from week 5)"
echo "== Health (first call may take ~20s while the app scales up from zero) =="
curl -s --max-time 60 "$URL/health"; echo
echo "== Ask a question through app -> APIM -> private Foundry =="
curl -s --max-time 60 -X POST "$URL/ask" -H "Content-Type: application/json" \
  -d '{"question":"How much does an international wire transfer cost?"}' \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print("Answer:", d.get("answer")); print("Mode:", d.get("mode"), "| latency ms:", d.get("latency_ms"))'
echo "== Agent: money moves only with confirmation =="
curl -s --max-time 60 -X POST "$URL/agent" -H "Content-Type: application/json" \
  -d '{"message":"Transfer 200 dollars from CHQ-1001 to SAV-2002"}' \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print("Answer:", d.get("answer")); print("Tool calls:", d.get("tool_calls"))'
