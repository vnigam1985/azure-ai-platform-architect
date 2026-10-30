#!/usr/bin/env bash
# Create the team key the bank app uses, with its own limits.
# This is the local version of an APIM product + subscription (week 4).
set -euo pipefail
GW=${GW:-http://localhost:4000}
ADMIN=${ADMIN:-sk-local-lab-key}
TEAM_KEY=${TEAM_KEY:-sk-team-retail-bank}   # LiteLLM keys must be 16+ characters
RPM=${RPM:-20}
TPM=${TPM:-20000}

out=$(curl -s "$GW/key/generate" \
  -H "Authorization: Bearer $ADMIN" -H "Content-Type: application/json" \
  -d "{\"key\":\"$TEAM_KEY\",\"key_alias\":\"$TEAM_KEY\",\"models\":[\"gpt-4.1-mini\",\"mock\"],\"rpm_limit\":$RPM,\"tpm_limit\":$TPM,\"metadata\":{\"cost_center\":\"retail-banking\"}}")

if echo "$out" | grep -q '"key"'; then
  echo "Created $TEAM_KEY: $RPM requests/min, $TPM tokens/min, models gpt-4.1-mini and mock"
elif echo "$out" | grep -q "already exists"; then
  echo "$TEAM_KEY already exists. Nothing to do."
else
  echo "Could not create the key: $out" >&2; exit 1
fi
