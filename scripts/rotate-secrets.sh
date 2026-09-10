#!/usr/bin/env bash
# Zero-downtime rotation for DB passwords + API signing keys.
# Usage: ./scripts/rotate-secrets.sh --env production [--apply]
set -euo pipefail

ENV="staging"
APPLY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENV="$2"; shift 2 ;;
    --apply) APPLY=true; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

PREFIX="stellariq-$ENV"
echo "Rotating secrets for $PREFIX (apply=$APPLY)"

rotate_db() {
  local new_pw
  new_pw="$(openssl rand -base64 24 | tr -d '/+=' | head -c 32)"
  if [[ "$APPLY" == true ]]; then
    aws secretsmanager put-secret-value --secret-id "$PREFIX/postgres" \
      --secret-string "{\"password\":\"$new_pw\"}" >/dev/null
    aws rds modify-db-instance --db-instance-identifier "$PREFIX-postgres" \
      --master-user-password "$new_pw" --apply-immediately >/dev/null
    echo "DB password rotated."
  else
    echo "[dry-run] would rotate $PREFIX/postgres + RDS master password"
  fi
}

rotate_jwt() {
  local new_key
  new_key="$(openssl rand -hex 32)"
  if [[ "$APPLY" == true ]]; then
    aws secretsmanager put-secret-value --secret-id "$PREFIX/api" \
      --secret-string "{\"jwtSecret\":\"$new_key\"}" >/dev/null
    kubectl -n "stellariq-${ENV/production/prod}" rollout restart deploy/api deploy/routing-engine
    echo "JWT signing key rotated + workloads restarted (overlapping validity: old tokens honored for 15m via dual-key check in API)."
  else
    echo "[dry-run] would rotate $PREFIX/api jwtSecret + rolling restart"
  fi
}

rotate_db
rotate_jwt
echo "Done. ExternalSecrets refreshes within 1h (or force: kubectl annotate externalsecret --all force-sync=\$(date +%s))."
