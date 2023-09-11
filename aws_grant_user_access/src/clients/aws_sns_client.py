from typing import Any, Dict
from aws_grant_user_access.src.clients import boto_try
from botocore.client import BaseClient


class AwsSnsClient:
    def __init__(self, boto_sns: BaseClient):
        self._sns = boto_sns

    def publish(self, sns_topic_arn: str, message: str) -> Dict[str, Any]:
        return boto_try(
            lambda: dict(self._sns.publish(TopicArn=sns_topic_arn, Message=message)),
            f"failed to publish a message to {sns_topic_arn}",
        )
