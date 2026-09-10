# Environment Promotion Strategy

Workspaces: `dev` (local/compose) → `staging` → `production`. Terraform workspaces per env under `terraform/envs/`.

## Promotion checklist

1. `dev`: feature works via `docker compose up` + local smoke.
2. Merge to `main` → auto-deploy to `staging` (green build required).
3. Staging soak: smoke suite + Grafana SLOs green for 24h (API p95 < 300ms, quote p95 < 1s).
4. `terraform plan -var-file=envs/production/terraform.tfvars` reviewed; migrations listed explicitly.
5. Manual approval (`production-approval` environment) → rolling update → smoke → auto-rollback on failure.

## Migration gating

- Migration Job runs BEFORE app rollout (see `kubernetes/jobs/migrate.yaml`).
- Backward-compatible migrations only (expand → migrate → contract). Breaking schema changes require a 2-release window.
- `db_version` metric must equal expected version before rollout proceeds.
