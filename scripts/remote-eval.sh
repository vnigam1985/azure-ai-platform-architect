#!/usr/bin/env bash
# Builds one script that carries eval_gate.py and the cases to the test VM,
# then runs it there with `az vm run-command invoke` (the app is VNet-only).
# Usage: RG=<rg> APP_FQDN=<fqdn> VM=<vm name> scripts/remote-eval.sh
set -euo pipefail
RG=${RG:?}; APP_FQDN=${APP_FQDN:?}; VM=${VM:?}
DIR=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT=$(cat <<OUTER
cat > /tmp/eval_gate.py <<'PYEOF'
$(cat "$DIR/scripts/eval_gate.py")
PYEOF
cat > /tmp/cases.json <<'JSONEOF'
$(cat "$DIR/evals/release-gate.json")
JSONEOF
python3 /tmp/eval_gate.py --url "https://${APP_FQDN}" --cases /tmp/cases.json
echo "EXIT_CODE=\$?"
OUTER
)
if [ "${DRY_RUN:-}" = 1 ]; then echo "$SCRIPT"; exit 0; fi
out=$(az vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript --scripts "$SCRIPT" --query "value[0].message" -o tsv)
echo "$out"
echo "$out" | grep -q "EXIT_CODE=0"
