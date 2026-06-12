#!/usr/bin/env bash
# Tear everything down so the demo stops costing money.
set -euo pipefail

cd "$(dirname "$0")/.."

echo ">> terraform destroy"
terraform -chdir=terraform destroy -auto-approve
echo ">> all resources removed."
