#!/usr/bin/env bash
#
# Note: The following environment variables are set by container-release build job
#   - CODEBUILD_INITIATOR
#   - CODEBUILD_BUILD_NUMBER
#   - TERRAFORM_PROVISIONER_ROLE_ARN

set -euo pipefail
IFS=$'\n\t'

ASSUME_ROLE_ARN="${LABS_TERRAFORM_PROVISIONER_ROLE_ARN}"

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

FILTER_PATHS=(
	main.py
	tests
	aws_grant_user_access
)

paths_have_update() {

	updates=$(git diff --name-only HEAD~1 HEAD)

	matches=""
	for p in "${FILTER_PATHS[@]}"; do
		if echo "${updates}" | grep "^${p}"; then
			matches+="${p} "
		fi
	done

	echo "${matches}"
}

main() {
	if [[ $(paths_have_update) != "" ]]; then
		set_aws_credentials
		make "container-release"
	else
		echo "No matching changes to build"
	fi
}

main "$@"
