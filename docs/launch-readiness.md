# Launch Readiness Review — sign-off for production rollout

Scale target (PRD 1148): 10+ protocols, 1M swaps/day, 10k users without redesign.

## Checklist

- [ ] Performance: k6 `perf/` green — cached API p95 < 300ms, dashboard < 2s, quote p95 < 1s
- [ ] Security: `security-scan.yml` green; no HIGH/CRITICAL images; secrets only via ExternalSecrets; TLS valid
- [ ] Monitoring: Prometheus scraping all jobs; Grafana SLO dashboards visible; alerts routed to Slack/PagerDuty
- [ ] Backups: latest restore test logged in `docs/disaster-recovery.md` (< 90 days)
- [ ] Secrets: rotation dry-run done (`rotate-secrets.sh --env production` without --apply)
- [ ] Scalability: HPA maxReplicas cover 10x staging load; RDS/Redis instance classes match prod tfvars
- [ ] Smoke: `./scripts/smoke.sh https://api.stellariq.io` fully green post-deploy

## Sign-off

| Role | Name | Date | Decision |
|---|---|---|---|
| Platform | | | |
| Security | | | |
| Product | | | |

Production rollout approved only with all boxes checked + 3 signatures.
