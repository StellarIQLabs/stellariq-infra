# stellariq-infra — Cloud, Deployment, Database & Operations

Infrastructure-as-code and operations layer for **StellarIQ** (DeFi intelligence platform for Stellar/Soroban).
Provisions cloud infrastructure, deploys services, and runs CI/CD, monitoring, logging, backups, and secrets.

> Spec source of truth: [`PRD.md`](../PRD.md) § `stellariq-infra` (line 335).

## Architecture at a glance

```
                    StellarIQ
                       │
        ┌──────────────┼──────────────┐
        │              │              │
   stellariq-app  stellariq-data  stellariq-contract  stellariq-infra  <-- this repo
   (product/API)  (data/intel)   (contracts)       (cloud/ops)
```

What this repo owns:

| Area | Implementation |
|---|---|
| Cloud network | `terraform/modules/networking` — VPC, public/private/database subnets, NAT, isolated SGs |
| Database | `terraform/modules/postgres` — RDS Postgres 16 + parameter group + RDS Proxy pooling + Secrets Manager |
| Cache/queues | `terraform/modules/redis` (ElastiCache) + `terraform/modules/queues` (SQS + DLQs, incl. FIFO price queue) |
| Backups | `terraform/modules/backups` — AWS Backup daily plan, KMS, retention, no-recent-backup alarm |
| Secrets | `terraform/modules/secrets` + `kubernetes/secrets/external-secrets.yaml` — Secrets Manager → ExternalSecrets, no secrets in git |
| Registry/artifacts | `terraform/modules/registry` — ECR repos per service + S3 WASM artifact bucket |
| Compute | `terraform/modules/cluster` — EKS + managed node group + autoscaler policy |
| Workloads | `kubernetes/{web,api,indexer,price-engine,analytics-engine,routing-engine}` |
| Edge | `kubernetes/ingress/` — TLS (cert-manager/Let's Encrypt), rate-limit + DDoS guards |
| CI/CD | `.github/workflows/` — reusable build/test/security/scan + staging auto-deploy + prod approval + auto-rollback |
| Contracts | `scripts/deploy-contracts.sh` + `scripts/soroban-networks.sh` (testnet/mainnet switch) |
| Simulation | `services/simulator` — pre-submission transaction simulation used by the API |
| Observability | `monitoring/` — Prometheus, Grafana SLO dashboards, Loki logs, alerts, uptime probes, consistency reconciler, OpenTelemetry + Sentry |
| Perf | `perf/` — k6 harnesses (API p95 < 300 ms, dashboard < 2 s, quotes < 1 s) |
| Runbooks | `docs/` — disaster recovery, promotion strategy, launch readiness |

## Repository layout

```
stellariq-infra/
├── terraform/                  # AWS IaC (providers, root wiring, 7 modules, 3 envs)
│   ├── providers.tf            # aws/kubernetes/helm/random providers + s3 remote-state backend
│   ├── main.tf                 # module wiring (networking → postgres/redis/queues/backups/secrets/registry/cluster)
│   ├── variables.tf            # region, env, sizing, Soroban RPC/passphrase vars
│   ├── backend.hcl.example     # remote-state template (copy to backend.hcl, never commit)
│   ├── soroban.tfvars.example  # Soroban RPC reference values
│   ├── modules/{networking,postgres,redis,queues,backups,secrets,registry,cluster}/
│   └── envs/{staging,production,demo}/terraform.tfvars
├── kubernetes/                 # K8s manifests
│   ├── namespaces/             # staging/prod namespaces, resource quotas, default-deny network policies
│   ├── web/                    # dashboard deployment + service + HPA + readiness probes
│   ├── api/                    # API deployment (env from secrets) + HPA to 10k-user/1M-swap headroom
│   ├── indexer/                # stateful indexer with persistent cursor volume
│   ├── price-engine/           # price publisher (cache write access)
│   ├── analytics-engine/       # deployment + OHLCV/volume CronJobs
│   ├── routing-engine/         # low-latency quote service (sub-second target, latency-tuned nodes + HPA)
│   ├── ingress/                # TLS ingress + rate-limit/DDoS ingress
│   ├── secrets/                # ExternalSecrets + monthly rotation CronJob
│   └── jobs/                   # db-migrate (pre-rollout) + demo-seed
├── docker/                     # pinned non-root base images (node:22.11.0, rust:1.83.0 + stellar-cli)
├── docker-compose.yml          # full local parity: postgres, redis, localstack(SQS/secrets), web, api, 4 engines
├── .env.example                # every required variable (copy to .env, never commit .env)
├── .github/workflows/          # reusable CI/CD (consumed by app + data repos)
├── scripts/                    # bootstrap, rollout/rollback, smoke, secrets rotation, contract deploy
├── services/simulator/         # tx simulation service (TypeScript/Express)
├── monitoring/                 # prometheus, grafana, loki/promtail, alerts, uptime, consistency, tracing
├── perf/                       # k6 load scripts
└── docs/                       # disaster-recovery, promotion, launch-readiness
```

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| terraform | ≥ 1.6 | `terraform init` for IaC |
| aws-cli | v2 | SSO login; IAM for EKS/ECR/RDS/Secrets Manager |
| kubectl | ≥ 1.29 | matched to EKS 1.30 |
| docker + compose | recent | local parity |
| stellar-cli | 21.5.0 | via `docker/soroban` base or `cargo install --locked --version 21.5.0 stellar-cli` |
| k6 | recent | only for `perf/` runs |
| node/pnpm | 22 / 9 | only for `services/simulator` |

## Quickstart — local (one command)

```bash
cp .env.example .env          # fill secrets; .env is git-ignored by convention — never commit it
./scripts/bootstrap.sh        # starts postgres+redis+localstack, then all services, then smoke test
# Web: http://localhost:3000   API: http://localhost:4000
docker compose down           # stop everything
```

`docker-compose.yml` runs: `postgres:16`, `redis:7`, `localstack` (SQS + Secrets Manager),
`api`, `web`, `indexer`, `price-engine`, `analytics-engine`, `routing-engine`.

## Quickstart — cloud (staging)

```bash
cp terraform/backend.hcl.example terraform/backend.hcl   # set state bucket/table once
./scripts/bootstrap-prod.sh staging                      # init, plan, kubeconfig, apply secrets, smoke
# then:
terraform -chdir=terraform init -backend-config=backend.hcl
terraform -chdir=terraform plan -var-file=envs/staging/terraform.tfvars -out=tfplan
terraform -chdir=terraform apply tfplan
```

Full details: `terraform/README.md` (plan/apply/rollback) and `kubernetes/README.md` (apply order, rollout, rollback).

## Terraform guide

Environments: `dev` (compose only, no cluster) → `staging` → `production`, plus ephemeral `demo`.
Each env has tuned sizing in `terraform/envs/<env>/terraform.tfvars`
(prod: `db.m6g.large` + 200 GB, `cache.m6g.large`, 3–12 `m6i` nodes; staging/demo smaller).

```bash
terraform -chdir=terraform workspace select staging
terraform -chdir=terraform plan -var-file=envs/staging/terraform.tfvars -out=tfplan
terraform -chdir=terraform apply tfplan
```

Module notes:

- **networking** — one NAT gateway per AZ; DB/Redis SGs accept traffic *only* from the app SG.
- **postgres** — Postgres 16, `pg_stat_statements`+`pgcrypto`, encrypted GP3, Multi-AZ, 7-day PITR retention,
  Performance Insights, CloudWatch logs; **RDS Proxy** endpoint is what apps use (`proxy_endpoint` output).
- **redis** — Redis 7 replication group, TLS + at-rest encryption, auto-failover, `volatile-lru`,
  snapshots; connection via Secrets Manager (`rediss://` URL).
- **queues** — `ingestion-jobs`, `analytics-pipelines`, FIFO `price-updates`, each with DLQ (max 5 receives).
- **backups** — daily `cron(0 2 * * ? *)` AWS Backup plan (30-day cold-storage lifecycle), KMS-rotated vault,
  plus a CloudWatch alarm when no backup completes in 26 h.
- **secrets** — `/api` + `/app-config` secrets, rotation Lambda role, IRSA role for External Secrets Operator.
- **registry** — immutable-tag ECR repos (`web, api, indexer, price-engine, analytics-engine, routing-engine, simulator`)
  with scan-on-push + lifecycle policy; versioned, encrypted, private S3 bucket for contract `.wasm`.
- **cluster** — EKS 1.30, private endpoint + public access, audit logging, managed node group with
  `maxUnavailable: 1` rolling updates, cluster-autoscaler IAM policy.

## Kubernetes guide

Apply order (also in `kubernetes/README.md`):

```bash
kubectl apply -f kubernetes/namespaces/
kubectl apply -f kubernetes/secrets/            # ExternalSecrets (needs IRSA role from terraform first)
kubectl apply -f kubernetes/jobs/migrate.yaml   # migrations BEFORE app rollout — schema always ahead of code
kubectl apply -f kubernetes/api kubernetes/web kubernetes/indexer \
  kubernetes/price-engine kubernetes/analytics-engine kubernetes/routing-engine
kubectl apply -f kubernetes/ingress/
```

Rollout / rollback by image SHA:

```bash
export ECR_REGISTRY=<acct>.dkr.ecr.us-east-1.amazonaws.com
./scripts/rollout.sh staging <sha>     # sets image on all services, waits for api rollout
./scripts/rollback.sh production       # kubectl rollout undo per service
```

Notable manifest details:

- `api` reads env from `stellariq-api-env` (ExternalSecret), liveness+readiness on `/health`,
  HPA 3→20 on CPU 65% + 500 rps/pod.
- `routing-engine` targets **sub-second quotes**: latency-tuned nodeSelector/toleration,
  `QUOTE_TIMEOUT_MS=800`, HPA 3→15, rolling update with surge.
- `indexer` is a StatefulSet with a 10 Gi cursor PVC and `Always` restart.
- `analytics-engine` ships `analytics-ohlcv` (`*/5`) and `analytics-volume` (`*/15`) CronJobs.
- Ingress terminates TLS for `app.`/`api.` hosts; a second ingress enforces
  100 rps / 1200 rpm / 50 connections edge limits with burst, returning 429/503 on shed.

## CI/CD (shared workflows)

Reusable workflows live here and are called identically from `stellariq-app`, `stellariq-data` and `stellariq-contract`
(see `.github/workflows/README.md` for consumer snippets):

| Workflow | Trigger | What it does |
|---|---|---|
| `build-images.yml` | `workflow_call` | buildx build + push `:sha` and `:latest` to ECR with GHA cache + provenance |
| `test.yml` | `workflow_call` | `pnpm lint` + `typecheck` + `test --ci` |
| `deploy-staging.yml` | push to `main` | verify → matrix-build all 6 services → `rollout.sh staging` → `smoke.sh` |
| `deploy-production.yml` | manual dispatch (`image_tag`) | `production-approval` gate → `rollout.sh production` → smoke, **auto-rollback on failure** |
| `security-scan.yml` | PR / `workflow_call` | `pnpm audit`, Semgrep SAST, Trivy HIGH/CRITICAL image scan (fail-closed), SARIF upload |

## Secrets management

- Never commit secrets: only `.env.example`, `backend.hcl.example`, `soroban.tfvars.example` are tracked.
- Cloud secrets live in AWS Secrets Manager (`<prefix>/postgres`, `<prefix>/redis`, `<prefix>/api`, `<prefix>/app-config`).
- `kubernetes/secrets/external-secrets.yaml` syncs them into `stellariq-api-env`, `stellariq-engines-env`,
  `stellariq-indexer-env` (hourly refresh).
- Rotation: `./scripts/rotate-secrets.sh --env production [--apply]` rotates the DB master password (RDS + secret)
  and the JWT signing key (dual-key overlap, then rolling restart); dry-run by default; monthly CronJob in-cluster.

## Soroban contract deploys

```bash
source scripts/soroban-networks.sh && resolve_network testnet   # or: mainnet
./scripts/deploy-contracts.sh --network testnet --wasm-bucket <wasm-bucket>
./scripts/deploy-contracts.sh --network mainnet --wasm-bucket <wasm-bucket> --source <account>
```

RPC/passphrase defaults mirror `terraform/variables.tf` and `terraform/soroban.tfvars.example`;
override via `SOROBAN_RPC_TESTNET / SOROBAN_RPC_MAINNET / SOROBAN_NETWORK` env.

## Transaction simulation

`services/simulator` (Express + TS strict) exposes:

- `GET /health`
- `POST /v1/simulate` `{ transactionXdr, network }` → proxies `simulateTransaction` to the
  configured Soroban RPC without submitting. Used by the API pre-submission (PRD 1144).

```bash
cd services/simulator && npm install && npm run build && npm start
```

## Observability & SLOs

| Signal | Target | Where |
|---|---|---|
| Cached API p95 | < 300 ms | Grafana `api-health.json` + `ApiDown`/`QuoteLatencyHigh` alerts |
| Quote p95 | < 1 s | routing-engine HPA + `perf/api-load.js` thresholds |
| Dashboard load | < 2 s | `perf/dashboard-load.js` |
| Availability | 99.9% | per-minute `monitoring/uptime/probe.yaml` on `/health` + `/v1/prices` |
| Ingestion lag | near-real-time | `indexer_ledger_lag` panel + `IngestionFailure` alert |
| TVL consistency | indexed == chain | `monitoring/consistency/reconciler.yaml` (15 min) + `TVLConsistencyGap` alert |

- **Metrics**: Prometheus scrapes api/routing/indexer/price + postgres/redis exporters (`monitoring/prometheus/`).
- **Logs**: Loki + Promtail, structured JSON from every service, 30-day retention (`monitoring/loki/`).
- **Tracing/errors**: OpenTelemetry Collector → Tempo + Sentry DSN via ExternalSecret (`monitoring/tracing/`).
- **Alerts** (`monitoring/prometheus/alert-rules.yml`): ApiDown, IngestionFailure, PriceEngineStale,
  BackupFailure, QuoteLatencyHigh → Slack `#ops` / PagerDuty by severity.

## Smoke tests (MVP definition of done, PRD 1406)

```bash
./scripts/smoke.sh https://api.staging.stellariq.io   # staging
./scripts/smoke.sh https://api.stellariq.io           # production
```

Covers: asset search → price → pools/liquidity → markets compare → quote. Exit non-zero on any failure
(and production deploy auto-rolls back on smoke failure).

## Backups & disaster recovery

See `docs/disaster-recovery.md`: PITR restore to a *new* instance first, cluster rebuild from terraform +
last-known-good SHA, Multi-AZ/region failover notes, and a quarterly test checklist with restore log.

## Environments & promotion

See `docs/promotion.md`: `dev → staging → production` workspaces, 24 h staging soak on SLOs,
explicit migration review, manual prod approval, backward-compatible migrations only
(expand → migrate → contract), `db_version` gate before rollout. Ephemeral sales/demo env:
`terraform/envs/demo/terraform.tfvars` + `kubernetes/jobs/demo-seed.yaml` (pre-loaded sample markets).

## Launch readiness

`docs/launch-readiness.md` is the production sign-off gate for the PRD 1148 scale target
(10+ protocols, 1 M swaps/day, 10 k users without redesign): perf, security, monitoring,
backups, secrets, scalability + 3 signatures (platform/security/product).

## Scripts reference

| Script | Purpose |
|---|---|
| `bootstrap.sh` | local: compose up (infra → all services) + smoke |
| `bootstrap-prod.sh <env>` | cloud: terraform init/plan guidance + kubeconfig + secrets + smoke |
| `rollout.sh <env> <sha>` | set image across services, wait on api |
| `rollback.sh <env>` | undo rollouts |
| `smoke.sh <base-url>` | MVP end-to-end checks |
| `rotate-secrets.sh --env <env> [--apply]` | zero-downtime secret rotation (dry-run default) |
| `deploy-contracts.sh --network <testnet\|mainnet>` | stellar-cli deploy + WASM upload |
| `soroban-networks.sh` | network switch (`resolve_network`) + RPC/passphrase env |

## Troubleshooting

- `terraform init` fails on backend: copy `backend.hcl.example` → `backend.hcl` and set the state bucket/table first.
- ExternalSecrets not syncing: check the IRSA role (`external_secrets_role_arn` output — replace `ACCOUNT_ID`/`OIDC_PROVIDER`
  placeholders) and `kubectl describe externalsecret -n stellariq-prod`.
- Pods pending: check `ResourceQuota` in `kubernetes/namespaces/quotas.yaml` and node-group sizing in env tfvars.
- Staging deploy stuck: `kubectl -n stellariq-staging rollout status deploy/api`; `rollback.sh staging` to revert.
- Smoke 502 on simulate: verify `SOROBAN_RPC_URL` secret and `services/simulator` health.

## Contributing

- One task = one commit (`feat(infra): <kebab-case>`), verified before commit (YAML parsed, `bash -n` clean).
- Never commit `.env`, `backend.hcl`, or any credential; update `.env.example` when adding variables.
- Consumer repos (`stellariq-app`, `stellariq-data`, `stellariq-contract`) must call the shared workflows here — don't fork build logic.

## License

See [LICENSE](LICENSE).
