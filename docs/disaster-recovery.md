# Disaster Recovery Runbook (PRD 359)

Restore tested quarterly. Owner: platform on-call.

## 1. Backup restore (RDS point-in-time)

1. Identify recovery point:
   `aws backup list-recovery-points-by-backup-vault --backup-vault-name stellariq-production-backup-vault`
2. PITR restore to a new instance first (never in place):
   `aws rds restore-db-instance-to-point-in-time --source-db-instance-identifier stellariq-production-postgres --target-db-instance-identifier stellariq-prod-restore-$(date +%F) --restore-time 2026-01-01T00:00:00Z`
3. Verify row counts + app smoke (`./scripts/smoke.sh`), then promote (swap proxy target).
4. Record result in `docs/dr-restore-log.md`.

## 2. Cluster rebuild

1. `terraform -chdir=terraform apply -var-file=envs/production/terraform.tfvars`
2. Re-apply namespaces/quotas/secrets: `kubectl apply -f kubernetes/namespaces -f kubernetes/secrets`
3. Roll out images pinned to last-known-good SHA (see deploy-production runs).
4. Run migration job + smoke suite.

## 3. Failover (multi-AZ / region)

- RDS Multi-AZ fails over automatically (~60–120s). Verify proxy endpoint, not instance endpoint, in app config.
- Redis: ElastiCache automatic failover to replica; verify `REDIS_URL` uses primary endpoint (DNS flips).
- Full-region failover: restore latest snapshot into DR region, update Route53, announce status page.

## 4. Quarterly test checklist

- [ ] Restore snapshot to ephemeral instance, run smoke
- [ ] Rebuild staging cluster from scratch
- [ ] Rotate one secret via `rotate-secrets.sh --env staging`
- [ ] Log evidence + date below

### Restore log

| Date | Tester | Scope | Result |
|---|---|---|---|
| _pending first run_ | | | |
