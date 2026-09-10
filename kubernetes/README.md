# Kubernetes deployments

## Apply order

```bash
kubectl apply -f kubernetes/namespaces/
kubectl apply -f kubernetes/secrets/        # ExternalSecrets (IRSA must exist first)
kubectl apply -f kubernetes/jobs/migrate.yaml
kubectl apply -f kubernetes/api kubernetes/web kubernetes/indexer \
  kubernetes/price-engine kubernetes/analytics-engine kubernetes/routing-engine
kubectl apply -f kubernetes/ingress/
```

Image rollout: `./scripts/rollout.sh <staging|production> <sha>`.
Rollback: `./scripts/rollback.sh <staging|production>`.
