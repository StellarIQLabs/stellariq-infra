#!/usr/bin/env bash
# Roll back last rollout. Usage: rollback.sh <env>
set -euo pipefail
ENV="${1:?env required}"
NS="stellariq-prod"; [[ "$ENV" == "staging" ]] && NS="stellariq-staging"
for svc in web api indexer price-engine analytics-engine routing-engine; do
  kubectl -n "$NS" rollout undo "deploy/$svc" 2>/dev/null || true
done
echo "Rollback issued in $NS."
