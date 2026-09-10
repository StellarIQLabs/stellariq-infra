#!/usr/bin/env bash
# One-click local bootstrap: clone -> running system.
set -euo pipefail
echo "== StellarIQ local bootstrap =="
command -v docker >/dev/null || { echo "Install docker first." >&2; exit 1; }
[ -f .env ] || { cp .env.example .env; echo "Created .env from .env.example — edit secrets, then re-run."; }
docker compose up --build -d postgres redis localstack
echo "Waiting for postgres..."
until docker compose exec -T postgres pg_isready -U stellariq >/dev/null 2>&1; do sleep 2; done
docker compose up --build -d
./scripts/smoke.sh http://localhost:4000 || true
echo "Web: http://localhost:3000  API: http://localhost:4000"
