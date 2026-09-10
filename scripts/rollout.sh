#!/usr/bin/env bash
# Rolling image update across all services. Usage: rollout.sh <env> <sha>
set -euo pipefail
ENV="${1:?env required}"; SHA="${2:?sha required}"
NS="stellariq-prod"; [[ "$ENV" == "staging" ]] && NS="stellariq-staging"
REG="${ECR_REGISTRY:?set ECR_REGISTRY}/stellariq-$ENV"
for svc in web api indexer price-engine analytics-engine routing-engine; do
  kubectl -n "$NS" set image "deploy/$svc" "*=$REG/$svc:$SHA" 2>/dev/null \
    || kubectl -n "$NS" set image "statefulset/$svc" "*=$REG/$svc:$SHA" 2>/dev/null \
    || echo "skip $svc (no deploy/statefulset yet)"
done
kubectl -n "$NS" rollout status deploy/api --timeout=300s
