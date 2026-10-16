from aws_grant_user_access.src.data.data import AWS_REGION
import boto3

from aws_grant_user_access.src.clients.aws_iam_client import AwsIamClient
from aws_grant_user_access.src.clients.aws_secrets_manager import AwsSecretsManagerClient

from dataclasses import dataclass


@dataclass(frozen=True)
class AwsCredentials:
    accessKeyId: str
    secretAccessKey: str
    sessionToken: str


class AwsClientFactory:
    def get_iam_client(self) -> AwsIamClient:
        return AwsIamClient(boto3.client("iam"))

    def get_secrets_manager_client(self) -> AwsSecretsManagerClient:
        return AwsSecretsManagerClient(boto3.client("secretsmanager", region_name=AWS_REGION))
