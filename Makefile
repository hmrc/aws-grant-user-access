.ONESHELL: # Execute all instructions in a target in one shell
SHELL = /bin/bash
.SHELLFLAGS = -euo pipefail -c

AWS_PROFILE ?= auth-RoleTerraformApplier
IMAGE_TAG ?=
LIVE_ACCOUNT_ID ?=
LABS_ACCOUNT_ID ?=
ECR_REPO = dkr.ecr.eu-west-2.amazonaws.com/grant-user-access

ifneq (, $(strip $(shell command -v aws-vault)))
	AWS_PROFILE_CMD := aws-vault exec $${AWS_PROFILE} --
endif

PYTHON_VERSION = $(shell head -1 .python-version)
PYTHON_COVERAGE_FAIL_UNDER_PERCENT = 100
PYTHON_SRC = *.py aws_grant_user_access/src/ tests/

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
	--env LIVE_ACCOUNT_ID \
	--env LABS_ACCOUNT_ID \
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
	@$(POETRY_DOCKER_MOUNT) black --line-length 120 --exclude=.venv $(PYTHON_SRC)

fmt-check: build
	@$(POETRY_DOCKER) black --line-length 120 --check $(PYTHON_SRC)

python-test: build
	@$(POETRY_DOCKER) pytest \
		--cov=aws_grant_user_access/src \
		--cov-fail-under=$(PYTHON_COVERAGE_FAIL_UNDER_PERCENT) \
		--no-cov-on-fail \
		--cov-report "term-missing:skip-covered" \
		--no-header \
		tests

mypy: build
	@$(POETRY_DOCKER) mypy --strict $(PYTHON_SRC)

bandit: build
	@$(POETRY_DOCKER) bandit -c bandit.yaml -r -q $(PYTHON_SRC)


test: python-test fmt-check md-check mypy bandit

ci: test

md-check:
	@docker pull zemanlx/remark-lint:0.2.0
	@docker run --rm -i -v $(PWD):/lint/input:ro zemanlx/remark-lint:0.2.0 --frail .

container-release:
	docker build --target lambda \
		--file Dockerfile \
		--build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
		--tag container-release:local .

check-image_tag:
ifndef IMAGE_TAG
	$(error "IMAGE_TAG env var not set")
endif

.PHONY: container-publish-%
container-publish-labs: export AWS_PROFILE := platsec-stackset-poc-RoleTerraformApplier
container-publish-labs: export ACCOUNT_ID := ${LABS_ACCOUNT_ID}
container-publish-live: export AWS_PROFILE := auth-RoleTerraformApplier
container-publish-live: export ACCOUNT_ID := ${LIVE_ACCOUNT_ID}
container-publish-%: check-image_tag check-live container-release terragrunt
	@docker tag container-release:local ${ACCOUNT_ID}.${ECR_REPO}:${IMAGE_TAG}
	@docker tag container-release:local ${ACCOUNT_ID}.${ECR_REPO}:latest
	@${AWS_PROFILE_CMD} $(TG) aws ecr get-login-password --region eu-west-2 \
		| docker login --username AWS --password-stdin ${ACCOUNT_ID}.${ECR_REPO}
	docker push ${ACCOUNT_ID}.${ECR_REPO}:${IMAGE_TAG}
	@docker push ${ACCOUNT_ID}.${ECR_REPO}:latest
	@${AWS_PROFILE_CMD} $(TG) aws ssm put-parameter \
    --name "/ecr/latest/grant-user-access" \
    --type "String" \
    --value "${IMAGE_TAG}" \
    --overwrite

check-live:
ifndef LIVE_ACCOUNT_ID
	$(error "LIVE_ACCOUNT_ID env var not set")
endif

check-labs:
ifndef LABS_ACCOUNT_ID
	$(error "LABS_ACCOUNT_ID env var not set")
endif

check-ci: check-live

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
validate-labs: export AWS_PROFILE := platsec-stackset-poc-RoleTerraformPlanner
validate-live: export AWS_PROFILE := auth-RoleTerraformPlanner
validate-ci: export AWS_PROFILE := auth-RoleTerraformPlanner
validate-%: check-% terragrunt
	@cd ./terraform/$*
	@find . -type d -name '.terragrunt-cache' | xargs -I {} rm -rf {}
	@$(AWS_PROFILE_CMD) $(TG) terragrunt run-all init
	@$(AWS_PROFILE_CMD) $(TG) terragrunt run-all validate >/dev/null
	echo "$@ OK"

# Run plan for labs or live environment
.PHONY: plan-%
plan-labs: export AWS_PROFILE := platsec-stackset-poc-RoleTerraformPlanner
plan-live: export AWS_PROFILE := auth-RoleTerraformPlanner
plan-ci: export AWS_PROFILE := auth-RoleTerraformPlanner
plan-%: check-% tf-fmt
	@cd ./terraform/$*
	@find . -type d -name '.terragrunt-cache' | xargs -I {} rm -rf {}
	@$(AWS_PROFILE_CMD) $(TG) terragrunt run-all init
	@$(AWS_PROFILE_CMD) $(TG) terragrunt run-all plan

# Run apply for labs or live environment
.PHONY: apply-%
apply-labs: export AWS_PROFILE := platsec-stackset-poc-RoleTerraformApplier
apply-live: export AWS_PROFILE := auth-RoleTerraformApplier
apply-ci: export AWS_PROFILE := auth-RoleTerraformApplier
apply-%: check-% terragrunt
	@cd ./terraform/$*
	@find . -type d -name '.terragrunt-cache' | xargs -I {} rm -rf {}
	@$(AWS_PROFILE_CMD) $(TG) terragrunt run-all init
	@$(AWS_PROFILE_CMD) $(TG) terragrunt run-all apply --terragrunt-non-interactive

# Bootstrap labs or live environment for terraform deployment
.PHONY: bootstrap-%
bootstrap-labs: export AWS_PROFILE := platsec-stackset-poc-RoleTerraformApplier
bootstrap-live: export AWS_PROFILE := auth-RoleTerraformApplier
bootstrap-%: check-labs check-live terragrunt
	@cd ./terraform/bootstrap/$*
	@find . -type d -name '.terragrunt-cache' | xargs -I {} rm -rf {}
	@$(AWS_PROFILE_CMD) $(TG) terragrunt init
ifeq ($(MAKECMDGOALS), bootstrap-labs)
	@$(AWS_PROFILE_CMD) $(TG) terragrunt apply
else
	@$(AWS_PROFILE_CMD) $(TG) terragrunt apply -auto-approve\
		-var environment_account_ids="{\"labs\": \"${LABS_ACCOUNT_ID}\", \"live\": \"${LIVE_ACCOUNT_ID}\"}"
endif
