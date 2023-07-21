ARG TF_BASE_TAG
FROM dockerhub.tax.service.gov.uk/alpine/terragrunt:${TF_BASE_TAG}

RUN apk update && apk add --no-cache aws-cli
