# Terraform deployments

## Plan / apply

```bash
cp terraform/backend.hcl.example terraform/backend.hcl  # fill bucket once
terraform -chdir=terraform init -backend-config=backend.hcl
terraform -chdir=terraform workspace select staging || terraform -chdir=terraform workspace new staging
terraform -chdir=terraform plan -var-file=envs/staging/terraform.tfvars -out=tfplan
terraform -chdir=terraform apply tfplan
```

## Roll back

- `terraform state list` + targeted `terraform destroy -target=...` for bad resources, or
- Re-apply previous known-good tag: `git checkout <sha> -- terraform/ && terraform apply`.
- Data-safe rule: never `destroy` postgres/redis without a verified snapshot.
