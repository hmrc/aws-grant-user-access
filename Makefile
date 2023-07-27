.ONESHELL: # Execute all instructions in a target in one shell
SHELL = /bin/bash
.SHELLFLAGS = -euo pipefail -c

AWS_PROFILE ?= auth-RoleTerraformApplier

ifneq (, $(strip $(shell command -v aws-vault)))
	AWS_PROFILE_CMD := aws-vault exec $${AWS_PROFILE} --
endif

# .PHONY: $(MAKECMDGOALS)

PYTHON_VERSION = $(shell head -1 .python-version)

POETRY_DOCKER = docker run \
	--interactive \
	--rm \
	build:local poetry run

POETRY_DOCKER_MOUNT = docker run \
	--interactive \
	--rm \
	--volume "$(PWD)/aws_grant_user_access:/build/aws_grant_user_access:z" \
	--volume "$(PWD)/main.py:/build/main.py:z" \
	--volume "$(PWD)/tests:/build/tests:z" \
	build:local poetry run

build:
	docker build --target dev \
		--build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
		--tag build:local .

# Terragrunt command accessible via Docker for user convenience and portability
# Any target that uses this should expect "terragrunt" target to have been run manually before
TG := docker run \
	--rm \
	--interactive \
	--volume "${PWD}:${PWD}" \
	--env AWS_DEFAULT_REGION=eu-west-2 \
	--env AWS_ACCESS_KEY_ID \
	--env AWS_SECRET_ACCESS_KEY \
	--env AWS_SESSION_TOKEN \
	--env TF_LOG \
	--env TERRAGRUNT_DOWNLOAD="${PWD}/terraform/.terragrunt-cache" \
	--user "$(shell id -u):$(shell id -g)" \
	--workdir "$${PWD}" \
	tg-worker

# Build image based on alpine/terragrunt with custom dependencies
.PHONY: terragrunt
terragrunt:
	docker build \
		--tag tg-worker \
		--build-arg "TF_BASE_TAG=$(shell head -n1 .terraform-version)" \
		-f tg.Dockerfile \
		.

fmt:
	@$(POETRY_DOCKER_MOUNT) black --line-length 120 --exclude=.venv .

fmt-check: build
	@$(POETRY_DOCKER) black --line-length 120 --check .

python-test: build
	@$(POETRY_DOCKER) pytest

test: python-test fmt-check md-check

ci: test

md-check:
	@docker pull zemanlx/remark-lint:0.2.0
	@docker run --rm -i -v $(PWD):/lint/input:ro zemanlx/remark-lint:0.2.0 --frail .

container-release:
	docker build --target lambda \
		--file Dockerfile \
		--build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
		--tag container-release:local .

IMAGE_TAG ?=
ECR_REPO = 979783897929.dkr.ecr.eu-west-2.amazonaws.com/grant-user-access

.PHONY: container-publish
container-publish: export AWS_PROFILE := platsec-stackset-poc-RoleTerraformProvisioner
container-publish: container-release terragrunt
	@docker tag container-release:local ${ECR_REPO}:${IMAGE_TAG}
	@docker tag container-release:local ${ECR_REPO}:latest
	@${AWS_PROFILE_CMD} $(TG) aws ecr get-login-password --region eu-west-2 \
		| docker login --username AWS --password-stdin ${ECR_REPO}
	@docker push ${ECR_REPO}:${IMAGE_TAG}
	@docker push ${ECR_REPO}:latest
	@${AWS_PROFILE_CMD} $(TG) aws ssm put-parameter \
    --name "/ecr/latest/grant-user-access" \
    --type "String" \
    --value "${IMAGE_TAG}" \
    --overwrite

# Format all terraform files
.PHONY: tf-fmt
tf-fmt: terragrunt
	@$(TG) terragrunt hclfmt
	@$(TG) terraform fmt -recursive .

# Check if all files are formatted
.PHONY: tf-fmt-check
tf-fmt-check: terragrunt
	@$(TG) terraform fmt -recursive -check .
	@$(TG) terragrunt hclfmt --terragrunt-check

.PHONY: tf-checks
tf-checks: tf-fmt-check  md-check

# Validate terraform configuration without need to accessing the state file
validate: validate-ci

.PHONY: validate-%
validate-labs: export AWS_PROFILE := platsec-stackset-poc-RoleTerraformProvisioner
validate-live: export AWS_PROFILE := auth-RoleTerraformPlanner
validate-ci: export AWS_PROFILE := auth-RoleTerraformPlanner
validate-%: terragrunt
	@cd ./terraform/$*
	@find . -type d -name '.terragrunt-cache' | xargs -I {} rm -rf {}
	@$(AWS_PROFILE_CMD) $(TG) terragrunt run-all init
	@$(AWS_PROFILE_CMD) $(TG) terragrunt run-all validate >/dev/null
	echo "$@ OK"

# Run plan for labs or live environment
.PHONY: plan-%
plan-labs: export AWS_PROFILE := platsec-stackset-poc-RoleTerraformProvisioner
plan-live: export AWS_PROFILE := auth-RoleTerraformPlanner
plan-ci: export AWS_PROFILE := auth-RoleTerraformPlanner
plan-%: tf-fmt
	@cd ./terraform/$*
	@find . -type d -name '.terragrunt-cache' | xargs -I {} rm -rf {}
	@$(AWS_PROFILE_CMD) $(TG) terragrunt run-all init
	@$(AWS_PROFILE_CMD) $(TG) terragrunt run-all plan

# Run apply for labs or live environment
.PHONY: apply-%
apply-labs: export AWS_PROFILE := platsec-stackset-poc-RoleTerraformProvisioner
apply-live: export AWS_PROFILE := auth-RoleTerraformApplier
apply-ci: export AWS_PROFILE := auth-RoleTerraformApplier
apply-%: terragrunt
	@cd ./terraform/$*
	@find . -type d -name '.terragrunt-cache' | xargs -I {} rm -rf {}
	@$(AWS_PROFILE_CMD) $(TG) terragrunt run-all init
	@$(AWS_PROFILE_CMD) $(TG) terragrunt run-all apply --terragrunt-non-interactive
