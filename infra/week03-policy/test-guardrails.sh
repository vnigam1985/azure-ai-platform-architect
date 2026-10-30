#!/usr/bin/env bash
# Week 3: try to break the rules and watch Azure Policy stop you.
# Uses `az deployment group validate`, which runs the policy check WITHOUT
# creating anything, so this test costs nothing.
# Usage: RG=<resource group> FOUNDRY=<week 2 Foundry name> ./test-guardrails.sh
set -u
RG=${RG:?set RG}; FOUNDRY=${FOUNDRY:?set FOUNDRY}
DIR=$(cd "$(dirname "$0")" && pwd)
pass=0; fail=0

expect_denied() {
  local label=$1; shift
  out=$(az deployment group validate -g "$RG" -f "$DIR/bad-examples.bicep" -p foundryName="$FOUNDRY" "$@" 2>&1)
  if echo "$out" | grep -q "RequestDisallowedByPolicy"; then
    echo "PASS  denied: $label"; pass=$((pass+1))
    echo "$out" | grep -o '"policyAssignmentDisplayName": *"[^"]*"' | head -1 | sed 's/^/      by /'
  else
    echo "FAIL  NOT denied: $label (is effect=Deny, and has it been 15 minutes?)"; fail=$((fail+1))
  fi
}

expect_denied "AI Services with API keys enabled"        -p scenario=keys
expect_denied "AI Services with public network access"   -p scenario=public
expect_denied "Global deployment type (residency)"       -p scenario=global
expect_denied "Model not on the approved list"           -p scenario=unapproved
echo
echo "$pass passed, $fail failed"
echo "If only the last test fails: the approved-models built-in evaluates in the data plane"
echo "and may not show up in validate. Try a real deployment in the portal; it should be blocked."
