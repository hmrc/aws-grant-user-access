SHELL = /bin/bash
.SHELLFLAGS = -euo pipefail -c

.PHONY: $(MAKECMDGOALS)

PYTHON_VERSION = $(shell head -1 .python-version)

POETRY_DOCKER = docker run \
	--interactive \
	--rm \
	build:local poetry run

POETRY_DOCKER_MOUNT = docker run \
	--interactive \
	--rm \
	--volume "$(PWD)/aws_grant_user_access:/build/aws_grant_user_access:z" \
	--volume "$(PWD)/tests:/build/tests:z" \
	build:local poetry run

build:
	docker build --target dev \
		--build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
		--tag build:local .

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