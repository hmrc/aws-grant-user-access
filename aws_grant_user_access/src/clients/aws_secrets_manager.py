from aws_grant_user_access.src.clients import boto_try
from botocore.client import BaseClient
from aws_grant_user_access.src.data.exceptions import AwsClientException


class AwsSecretsManagerClient:
    def __init__(self, boto_secrets_manager: BaseClient):
        self._secrets_manager = boto_secrets_manager

    def get_secret_value(self, secret_id: str) -> str:
        response = boto_try(
            lambda: self._secrets_manager.get_secret_value(SecretId=secret_id),
            f"failed to get secret {secret_id}",
        )

        secret_string = response.get("SecretString")
        if not isinstance(secret_string, str):
            raise AwsClientException(f"failed to get secret {secret_id}: expected a string secret")

        return secret_string
