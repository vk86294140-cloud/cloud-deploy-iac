#!/usr/bin/env bash
# Provision infra and push the first image — for a manual/local bootstrap.
# Day-to-day deploys happen via .github/workflows/deploy.yml.
set -euo pipefail

cd "$(dirname "$0")/.."

REGION="${AWS_REGION:-us-east-1}"
PROJECT="cloud-deploy-iac"

echo ">> terraform apply (creates ECR, ECS, ALB, alarms)"
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve

REPO=$(terraform -chdir=terraform output -raw ecr_repository_url)
ACCOUNT_REGISTRY="${REPO%/*}"

echo ">> build & push image to $REPO"
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$ACCOUNT_REGISTRY"
docker build -t "$REPO:latest" ./app
docker push "$REPO:latest"

echo ">> force a new deployment so ECS pulls the image"
aws ecs update-service --cluster "$PROJECT" --service "$PROJECT" --force-new-deployment >/dev/null
aws ecs wait services-stable --cluster "$PROJECT" --services "$PROJECT"

echo ">> done. Service URL:"
terraform -chdir=terraform output -raw service_url
echo
