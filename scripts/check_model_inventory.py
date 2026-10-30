#!/usr/bin/env python3
"""Check the model inventory (governance/model-inventory/model_inventory.yaml).

1. Every model has the required fields, a valid risk rating and a review date
   that isn't in the past.
2. Optional: --deployed <file> takes the JSON from
     az cognitiveservices account deployment list -g <rg> -n <foundry>
   and fails if anything is deployed that isn't in the inventory, or if the
   deployed model, version or deployment type doesn't match.

Usage:
  python3 scripts/check_model_inventory.py
  python3 scripts/check_model_inventory.py --deployed deployments.json
"""
import argparse
import datetime as dt
import json
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
INVENTORY = ROOT / "governance" / "model-inventory" / "model_inventory.yaml"
REQUIRED = [
    "id", "name", "deployment_name", "provider_model", "provider_model_version", "deployment_type",
    "region", "business_owner", "technical_owner", "purpose", "risk_rating", "data_classification",
    "human_oversight", "controls", "validation", "monitoring", "next_review", "status",
]
RISK = {"Low", "Medium", "High"}


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--inventory", default=str(INVENTORY))
    p.add_argument("--deployed", help="JSON from az cognitiveservices account deployment list")
    args = p.parse_args()

    models = yaml.safe_load(open(args.inventory))["models"]
    problems: list[str] = []
    today = dt.date.today()

    for m in models:
        mid = m.get("id", "<no id>")
        for f in REQUIRED:
            if not m.get(f):
                problems.append(f"{mid}: missing '{f}'")
        if m.get("risk_rating") not in RISK:
            problems.append(f"{mid}: risk_rating must be one of {sorted(RISK)}")
        if not (m.get("validation") or {}).get("last_validated"):
            problems.append(f"{mid}: validation.last_validated is missing")
        try:
            if dt.date.fromisoformat(str(m.get("next_review"))) < today:
                problems.append(f"{mid}: next_review {m['next_review']} is in the past")
        except ValueError:
            problems.append(f"{mid}: next_review must be YYYY-MM-DD")

    if args.deployed:
        deployed = json.load(open(args.deployed))
        by_name = {m["deployment_name"]: m for m in models}
        for d in deployed:
            name = d["name"]
            model = d["properties"]["model"]
            sku = d["sku"]["name"]
            m = by_name.get(name)
            if not m:
                problems.append(f"deployed '{name}' ({model['name']} {model.get('version')}) is NOT in the inventory")
                continue
            if model["name"] != m["provider_model"]:
                problems.append(f"{name}: deployed model {model['name']} != inventory {m['provider_model']}")
            if str(model.get("version")) != str(m["provider_model_version"]):
                problems.append(f"{name}: deployed version {model.get('version')} != inventory {m['provider_model_version']}")
            if sku != m["deployment_type"]:
                problems.append(f"{name}: deployed type {sku} != inventory {m['deployment_type']}")

    if problems:
        print("MODEL INVENTORY: FAIL")
        for pr in problems:
            print(" -", pr)
        return 1
    print(f"MODEL INVENTORY: OK ({len(models)} model(s){', matches what is deployed' if args.deployed else ''})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
