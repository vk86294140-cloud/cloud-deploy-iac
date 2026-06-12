.PHONY: fmt validate plan apply destroy build run

fmt:
	terraform -chdir=terraform fmt -recursive

validate:
	terraform -chdir=terraform init -backend=false && terraform -chdir=terraform validate

plan:
	terraform -chdir=terraform plan

apply:
	bash scripts/deploy.sh

destroy:
	bash scripts/destroy.sh

build:
	docker build -t cloud-deploy-iac:local ./app

run: build
	docker run --rm -p 8000:8000 cloud-deploy-iac:local
