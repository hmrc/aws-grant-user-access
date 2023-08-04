#!/usr/bin/env bash
#
# Note: The following environment variables are set by PR build job
#   - CODEBUILD_INITIATOR
#   - CODEBUILD_BUILD_NUMBER
#   - TERRAFORM_APPLIER_ROLE_ARN

set -euo pipefail
IFS=$'\n\t'

TARGET=$1
ASSUME_ROLE_ARN="${TERRAFORM_APPLIER_ROLE_ARN}"

# a simple way to check for presence of *_ACCOUNT_IDS env vars that should be exported by codebuild
_SUPPORTED_ACCOUNT_IDS="${LABS_ACCOUNT_ID} ${LIVE_ACCOUNT_ID}"

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

main() {
	set_aws_credentials
	make "apply-${TARGET}"
}

main "$@"
