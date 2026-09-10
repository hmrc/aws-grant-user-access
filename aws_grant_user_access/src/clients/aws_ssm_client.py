from aws_grant_user_access.src.clients import boto_try
from botocore.client import BaseClient


class AwsSsmClient:
    def __init__(self, boto_ssm: BaseClient):
        self._ssm = boto_ssm

    def get_parameter(self, name: str) -> str:
        return boto_try(
            lambda: str(self._ssm.get_parameter(Name=name, WithDecryption=True)["Parameter"]["Value"]),
            f"failed to get parameter {name}",
        )
