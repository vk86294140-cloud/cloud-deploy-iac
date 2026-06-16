# cloud-deploy-iac

[![CI](https://github.com/vk86294140-cloud/cloud-deploy-iac/actions/workflows/ci.yml/badge.svg)](https://github.com/vk86294140-cloud/cloud-deploy-iac/actions/workflows/ci.yml)
![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-7B42BC)
![AWS](https://img.shields.io/badge/AWS-ECS%20Fargate-FF9900)
![License](https://img.shields.io/badge/license-MIT-green)

Production-style **Infrastructure-as-Code + CI/CD** that ships a containerized
service to **AWS ECS Fargate** behind an **Application Load Balancer**, with
**CloudWatch** logging, alarms, and a dashboard — all defined in **Terraform**
and deployed by **GitHub Actions** using **OIDC** (no long-lived AWS keys).

```
 GitHub push ─► Actions ─► build image ─► ECR
                              │
                              ▼
        Terraform ──► ALB ──► ECS Fargate service (2 tasks)
                              │
                              ▼
                  CloudWatch logs · alarms · dashboard ─► SNS email
```

## What it provisions

| Component | Resource |
| --- | --- |
| Container registry | ECR repo with scan-on-push + lifecycle policy (keep last 10) |
| Compute | ECS Fargate cluster + service (configurable task count/CPU/memory) |
| Autoscaling | Application Auto Scaling target + 2 target-tracking policies (CPU, ALB requests/task) |
| Networking | ALB + target group + listener; least-privilege security groups |
| IAM | Task execution role (ECR pull + log write) |
| Observability | CloudWatch log group, 3 alarms (CPU, unhealthy hosts, 5xx), dashboard, SNS topic |

The deploy target is a small FastAPI service in [`app/`](app/) — swap it for any
container that listens on a port and exposes a health endpoint.

## Highlights

- **Keyless CI/CD.** GitHub Actions assumes an AWS IAM role via OIDC — there are
  no `AWS_ACCESS_KEY_ID` secrets to leak or rotate.
- **Immutable, traceable deploys.** Every image is tagged with the git SHA;
  `/health` echoes the deployed commit. ECS rolls forward via a new task
  revision and waits for `services-stable`.
- **Scales with load.** Application Auto Scaling holds the service between
  `min_capacity` and `max_capacity`, scaling on whichever bites first — average
  CPU or ALB requests-per-task. Terraform seeds the initial count and then gets
  out of the way (`ignore_changes = [desired_count]`).
- **Cost-aware by default.** Uses the default VPC (no NAT-gateway bill) and a
  one-command `make destroy`. Estimated demo cost ≈ **$20-30/mo** (ALB + 2 small
  Fargate tasks); **$0** when destroyed.
- **CI that actually checks things.** `terraform fmt -check` + `validate`, plus a
  real container build-and-smoke-test on every PR.

## Prerequisites

- An AWS account, Terraform ≥ 1.5, Docker, and the AWS CLI (for the local path).
- For GitHub deploys: an IAM role trusting GitHub's OIDC provider. Set its ARN as
  the repo variable `AWS_DEPLOY_ROLE_ARN` (Settings → Secrets and variables →
  Actions → Variables).

## Deploy (local bootstrap)

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars   # optional edits
make validate          # fmt + validate, no AWS needed
bash scripts/deploy.sh # terraform apply, build, push, roll the service
# -> prints the public service URL

curl http://<alb-dns-name>/health
# {"status":"ok","host":"ip-10-0-...","commit":"dev"}
```

## Deploy (GitHub Actions)

1. Create the OIDC IAM role and set `AWS_DEPLOY_ROLE_ARN` (repo variable).
2. Run the infra once (`bash scripts/deploy.sh`, or `terraform apply`) to create
   the ECR repo, cluster, and service.
3. Push to `main`. [`deploy.yml`](.github/workflows/deploy.yml) builds the image,
   pushes it to ECR tagged with the SHA, registers a new task definition, and
   rolls the service — waiting for it to stabilize.

## Observability

- **Logs:** `/ecs/cloud-deploy-iac` in CloudWatch Logs.
- **Dashboard:** ECS CPU/memory and ALB request/5xx — URL in `terraform output dashboard_url`.
- **Alarms** (→ SNS, optional email via `alarm_email`):
  - CPU > 80% for 2 min
  - any unhealthy ALB target
  - > 5 target 5xx responses in a minute

## Tear down

```bash
make destroy   # terraform destroy -auto-approve
```

## Layout

```
app/                     FastAPI service + Dockerfile (the deploy target)
terraform/
  versions.tf            providers + (optional) S3 remote-state backend
  variables.tf           region, sizing, alarm email, ...
  network.tf             default-VPC data sources + security groups
  iam.tf                 ECS task execution role
  main.tf                ECR, ECS cluster/task/service, ALB
  monitoring.tf          log group, alarms, SNS, dashboard
  outputs.tf             service URL, ECR URL, dashboard URL
.github/workflows/
  ci.yml                 terraform fmt/validate + container smoke test
  deploy.yml             OIDC -> build -> push -> ECS rolling deploy
scripts/                 deploy.sh / destroy.sh
```

## Notes & trade-offs

- **Default VPC + public tasks** keep the demo cheap. For production, move tasks
  to private subnets behind NAT and terminate TLS on the ALB (ACM cert + HTTPS
  listener). Both are localized changes in `network.tf` / `main.tf`.
- **State** is local by default; uncomment the S3 backend in `versions.tf` for
  team use with locking.
- This repo deploys a placeholder service, but the same infra deploys any
  container — point `container_image` at, for example, my
  [credit-risk-mlops](https://github.com/vk86294140-cloud/credit-risk-mlops)
  model-serving image.

## License

MIT — see [LICENSE](LICENSE).
