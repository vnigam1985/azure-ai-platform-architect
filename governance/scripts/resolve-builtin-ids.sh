#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Look up the built-in policy definition IDs used by ai-guardrails.json.
# Built-in display names change over time (Microsoft renamed several when
# "Azure AI Foundry" became "Microsoft Foundry"), so resolve them live
# instead of trusting a copied GUID.
#
# Usage: ./resolve-builtin-ids.sh
# Needs: Azure CLI, logged in (az login)
# -----------------------------------------------------------------------------
set -euo pipefail

names=(
  "Azure AI Services resources should have key access disabled (disable local authentication)"
  "Azure AI Services resources should restrict network access"
  "Azure AI Services resources should use Azure Private Link"
  "Foundry model deployments should only use approved models"
  "Foundry model deployments should meet eligibility requirements"
  "Azure AI Search services should disable public network access"
  "Azure AI Search services should have local authentication methods disabled"
  "Configure Azure AI Services resources to disable local key access (disable local authentication)"
)

printf '%-100s %s\n' "DISPLAY NAME" "DEFINITION ID"
for n in "${names[@]}"; do
  id=$(az policy definition list --query "[?displayName=='${n}'].id | [0]" -o tsv 2>/dev/null || true)
  printf '%-100s %s\n' "$n" "${id:-NOT FOUND (name may have changed, search the portal)}"
done

echo
echo "Tip: search for partial names when a lookup fails:"
echo "  az policy definition list --query \"[?contains(displayName,'Foundry')].{name:displayName,id:id}\" -o table"
