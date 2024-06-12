from aws_grant_user_access.src.data.data import AWS_REGION
import boto3

from aws_grant_user_access.src.clients.aws_iam_client import AwsIamClient
from aws_grant_user_access.src.clients.aws_sns_client import AwsSnsClient

from dataclasses import dataclass


@dataclass(frozen=True)
class AwsCredentials:
    accessKeyId: str
    secretAccessKey: str
    sessionToken: str


class AwsClientFactory:
    def get_iam_client(self) -> AwsIamClient:
        return AwsIamClient(boto3.client("iam"))

    def get_sns_client(self) -> AwsSnsClient:
        return AwsSnsClient(boto3.client("sns", region_name=AWS_REGION))
