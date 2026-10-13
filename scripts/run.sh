#!/usr/bin/env bash
#
# Unified entrypoint for terraform plan/apply, used by the platsec-ci-terraform
# pipelines (platsec_terraform_pipeline / terraform_pr_builder). Those shared
# modules only know about "development" and "production" as target names, but
# this repo's own terraform/Makefile layout still uses "labs" and "live" (kept
# as-is to avoid any risk to the existing state bucket/backend naming, which is
# derived from the environment name). This script is the thin translation
# layer between the two.
#
# Note: The following environment variables are set by the CI build job
#   - CODEBUILD_INITIATOR
#   - CODEBUILD_BUILD_NUMBER
#   - TERRAFORM_APPLIER_ROLE_ARN (apply)
#   - DEVELOPMENT_TERRAFORM_PLANNER_ROLE_ARN / PRODUCTION_TERRAFORM_PLANNER_ROLE_ARN (plan)

set -euo pipefail
IFS=$'\n\t'

CMD=$1
TARGET=$2
ASSUME_ROLE_ARN=""
INTERNAL_TARGET=""

set_internal_target() {
	case "${TARGET}" in
	development)
		INTERNAL_TARGET=labs
		;;
	production)
		INTERNAL_TARGET=live
		;;
	*)
		echo "Unknown target '${TARGET}', expected 'development' or 'production'" >&2
		exit 1
		;;
	esac
}

set_assume_role_arn() {
	if [[ "${CMD}" == "apply" ]]; then
		ASSUME_ROLE_ARN="${TERRAFORM_APPLIER_ROLE_ARN}"
	else
		case "${TARGET}" in
		development)
			ASSUME_ROLE_ARN="${DEVELOPMENT_TERRAFORM_PLANNER_ROLE_ARN}"
			;;
		production)
			ASSUME_ROLE_ARN="${PRODUCTION_TERRAFORM_PLANNER_ROLE_ARN}"
			;;
		esac
	fi
}

set_aws_credentials() {
	STS=$(
		aws sts assume-role \
			--role-arn "${ASSUME_ROLE_ARN}" \
			--role-session-name "${CODEBUILD_INITIATOR#*/}-${CODEBUILD_BUILD_NUMBER}" \
			--query "Credentials"
	)

	AWS_ACCESS_KEY_ID="$(jq -r '.AccessKeyId' <<<"${STS}")"
	AWS_SECRET_ACCESS_KEY="$(jq -r '.SecretAccessKey' <<<"${STS}")"
	AWS_SESSION_TOKEN="$(jq -r '.SessionToken' <<<"${STS}")"

	export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

run_cmd() {
	if [[ "${CMD}" == "plan" ]]; then
		make "validate-${INTERNAL_TARGET}"
		make "plan-${INTERNAL_TARGET}"
	else
		make "apply-${INTERNAL_TARGET}"
	fi
}

main() {
	set_internal_target
	set_assume_role_arn
	set_aws_credentials
	run_cmd
}

main "$@"
