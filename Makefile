.ONESHELL: # Execute all instructions in a target in one shell
SHELL = /bin/bash
.SHELLFLAGS = -euo pipefail -c

AWS_PROFILE ?= auth-RoleTerraformApplier

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
	--env TF_LOG \
	--env TG_DOWNLOAD_DIR="${PWD}/terraform/.terragrunt-cache" \
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

fmt: build
	@echo "black fix"
	@$(POETRY_DOCKER_MOUNT) black --line-length 120 --exclude=.venv $(PYTHON_SRC)

fmt-check: build
	@echo "black checks"
	@$(POETRY_DOCKER) black --line-length 120 --check $(PYTHON_SRC)

python-test: build
	@$(POETRY_DOCKER) pytest \
		--cov=aws_grant_user_access/src \
		--cov-fail-under=$(PYTHON_COVERAGE_FAIL_UNDER_PERCENT) \
		--no-cov-on-fail \
		--cov-report "term-missing:skip-covered" \
		--no-header \
		tests

flake8: build
	@echo "flake8 checks"
	@$(POETRY_DOCKER) flake8 --max-line-length 120 --exclude=.venv $(PYTHON_SRC)

mypy: build
	@echo "mypy checks"
	@$(POETRY_DOCKER) mypy --strict $(PYTHON_SRC)

bandit: build
	@echo "bandit checks"
	@$(POETRY_DOCKER) bandit -c bandit.yaml -r -q $(PYTHON_SRC)


test: flake8 md-check bandit fmt-check python-test mypy

ci: test

REMARK_LINT_VERSION = 0.3.5
md-check:
	@echo "remark-lint checks"
	@docker run --pull missing --rm -i -v $(PWD):/lint/input:ro ghcr.io/zemanlx/remark-lint:${REMARK_LINT_VERSION} --frail .

# Update (to best of tools ability) md linter findings
.PHONY: md-fix
md-fix:
	@docker run --pull missing --rm -i -v $(PWD):/lint/input:rw ghcr.io/zemanlx/remark-lint:${REMARK_LINT_VERSION} . -o

container-release:
	docker build --target lambda \
		--file Dockerfile \
		--build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
		--tag container-release:local .

# Format all terraform files
.PHONY: tf-fmt
tf-fmt: terragrunt
	@$(TG) terragrunt hcl format
	@$(TG) terraform fmt -recursive .

# Check if all files are formatted
.PHONY: tf-fmt-check
tf-fmt-check: terragrunt
	@$(TG) terraform fmt -recursive -check .
	@$(TG) terragrunt hcl format --check

.PHONY: tf-checks
tf-checks: tf-fmt-check  md-check

.PHONY: all-checks
all-checks: tf-checks

# Validate terraform configuration without need to accessing the state file
validate: validate-labs validate-live

.PHONY: validate-%
validate-labs: export AWS_PROFILE := platsec-development-RoleTerraformPlanner
validate-live: export AWS_PROFILE := auth-RoleTerraformPlanner
validate-%: terragrunt
	@cd ./terraform/$*
	@find . -type d -name '.terragrunt-cache' | xargs -I {} rm -rf {}
	@$(AWS_PROFILE_CMD) $(TG) terragrunt init --all --non-interactive
	@$(AWS_PROFILE_CMD) $(TG) terragrunt validate --all --non-interactive >/dev/null
	echo "$@ OK"

# Run plan for labs or live environment
.PHONY: plan-%
plan-labs: export AWS_PROFILE := platsec-development-RoleTerraformPlanner
plan-live: export AWS_PROFILE := auth-RoleTerraformPlanner
plan-%: tf-fmt
	@cd ./terraform/$*
	@find . -type d -name '.terragrunt-cache' | xargs -I {} rm -rf {}
	@$(AWS_PROFILE_CMD) $(TG) terragrunt init --all --non-interactive
	@$(AWS_PROFILE_CMD) $(TG) terragrunt plan --all --non-interactive

# Run plan for labs or live environment
.PHONY: plan-%
plan-bootstrap-labs: export AWS_PROFILE := platsec-development-RoleTerraformPlanner
plan-bootstrap-live: export AWS_PROFILE := auth-RoleTerraformPlanner
plan-bootstrap-%: tf-fmt
	@cd ./terraform/bootstrap/$*
	@find . -type d -name '.terragrunt-cache' | xargs -I {} rm -rf {}
	@$(AWS_PROFILE_CMD) $(TG) terragrunt init
	@$(AWS_PROFILE_CMD) $(TG) terragrunt plan

# Run apply for labs or live environment
.PHONY: apply-%
apply-labs: export AWS_PROFILE := platsec-development-RoleTerraformApplier
apply-live: export AWS_PROFILE := auth-RoleTerraformApplier
apply-%: terragrunt
	@cd ./terraform/$*
	@find . -type d -name '.terragrunt-cache' | xargs -I {} rm -rf {}
	@$(AWS_PROFILE_CMD) $(TG) terragrunt init --all --non-interactive
	@$(AWS_PROFILE_CMD) $(TG) terragrunt apply --all --non-interactive

# Bootstrap labs or live environment for terraform deployment
.PHONY: bootstrap-%
bootstrap-labs: export AWS_PROFILE := platsec-development-RoleTerraformApplier
bootstrap-live: export AWS_PROFILE := auth-RoleTerraformApplier
bootstrap-%: terragrunt
	@find . -type d -name '.terragrunt-cache' | xargs -I {} rm -rf {}
	@cd ./terraform/bootstrap/$*
	@$(AWS_PROFILE_CMD) $(TG) terragrunt init
	@$(AWS_PROFILE_CMD) $(TG) terragrunt apply
