#!/usr/bin/env bash
# Cloud bootstrap for a new engineer: clone -> staging running.
set -euo pipefail
ENV="${1:-staging}"
echo "== StellarIQ cloud bootstrap ($ENV) =="
command -v terraform >/dev/null || { echo "Install terraform >= 1.6." >&2; exit 1; }
command -v aws >/dev/null || { echo "Install aws-cli + SSO login first." >&2; exit 1; }
command -v kubectl >/dev/null || { echo "Install kubectl." >&2; exit 1; }
terraform -chdir=terraform init -backend-config=backend.hcl
terraform -chdir=terraform plan -var-file="envs/$ENV/terraform.tfvars" -out=tfplan
echo "Review the plan above, then: terraform -chdir=terraform apply tfplan"
aws eks update-kubeconfig --name "stellariq-$ENV" --region "${AWS_REGION:-us-east-1}"
kubectl apply -f kubernetes/namespaces/ -f kubernetes/secrets/
./scripts/smoke.sh "https://api.$ENV.stellariq.io" || true
echo "Done. See terraform/README.md + kubernetes/README.md."
