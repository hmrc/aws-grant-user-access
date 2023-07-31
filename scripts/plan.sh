#!/usr/bin/env bash
#
# Note: The following environment variables are set by PR build job
#   - CODEBUILD_INITIATOR
#   - CODEBUILD_BUILD_NUMBER
#   - TERRAFORM_PROVISIONER_ROLE_ARN

set -euo pipefail
IFS=$'\n\t'

TARGET=$1

set_aws_credentials() {
	case "${TARGET}" in
	labs)
		assume_role_arn="${LABS_TERRAFORM_PROVISIONER_ROLE_ARN}"
		;;
	live)
		assume_role_arn="${LIVE_TERRAFORM_PLANNER_ROLE_ARN}"
		;;
	*)
		assume_role_arn="${LIVE_TERRAFORM_PLANNER_ROLE_ARN}"
		;;
	esac
	STS=$(
		aws sts assume-role \
			--role-arn "${assume_role_arn}" \
			--role-session-name "${CODEBUILD_INITIATOR#*/}-${CODEBUILD_BUILD_NUMBER}" \
			--query "Credentials"
	)

	AWS_ACCESS_KEY_ID="$(jq -r '.AccessKeyId' <<<"${STS}")"
	AWS_SECRET_ACCESS_KEY="$(jq -r '.SecretAccessKey' <<<"${STS}")"
	AWS_SESSION_TOKEN="$(jq -r '.SessionToken' <<<"${STS}")"

	export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

main() {
	set_aws_credentials
	make "validate-${TARGET}"
	make "plan-${TARGET}"
}

main "$@"
