from typing import Any, Dict, List
from aws_grant_user_access.src.clients.aws_sns_client import AwsSnsClient
from aws_grant_user_access.src.data.data import AWS_IAM_TIME_FORMAT

from aws_grant_user_access.src.grant_time_window import GrantTimeWindow


class SNSMessage:
    @staticmethod
    def generate(grantor: str, usernames: List[str], role_arn: str, time_window: GrantTimeWindow) -> Dict[str, Any]:
        return {
            "detailType": "GrantUserAccessLambda",
            "roleArn": role_arn,
            "grantor": grantor,
            "usernames": usernames,
            "startTime": time_window.start_time.strftime(AWS_IAM_TIME_FORMAT),
            "endTime": time_window.end_time.strftime(AWS_IAM_TIME_FORMAT),
        }


class SNSMessagePublisher:
    def __init__(self, sns_client: AwsSnsClient) -> None:
        self.sns_client = sns_client

    def publish_sns_message(self, sns_topic_arn: str, message: str) -> Dict[str, Any]:
        return self.sns_client.publish(sns_topic_arn=sns_topic_arn, message=message)
