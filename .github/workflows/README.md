# Shared GitHub Actions (PRD 356)
# Reusable workflows in this repo are the single source of build logic.

| Workflow | Purpose | Called by |
|---|---|---|
| `build-images.yml` | Build, tag with commit SHA, push to ECR with cache | app, data |
| `test.yml` | lint + typecheck + tests on PRs | app, data |
| `deploy-staging.yml` | Auto-deploy main to staging + smoke | infra |
| `deploy-production.yml` | Manual approval + rolling update + auto-rollback | infra |
| `security-scan.yml` | Deps, SAST, image scan | app, data |

## Consumer snippet (app / data repos)

```yaml
jobs:
  test:
    uses: StellarIQLabs/stellariq-infra/.github/workflows/test.yml@main
  build:
    uses: StellarIQLabs/stellariq-infra/.github/workflows/build-images.yml@main
    with:
      service: api
      dockerfile: ./apps/api/Dockerfile
      registry: ${{ vars.ECR_REGISTRY }}/stellariq-staging
    secrets:
      aws-role-arn: ${{ secrets.AWS_ROLE_ARN }}
```
