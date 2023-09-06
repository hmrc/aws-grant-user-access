from typing import Dict, List

from aws_grant_user_access.src.grant_time_window import GrantTimeWindow


class SNSMessagePublisher:
    def __init__(self, sns_client) -> None:
        self.sns_client = sns_client

    def publish_sns_message(self, topic_arn: str, message: str) -> Dict:
        response = self.sns_client.publish(TopicArn=topic_arn, Message=message)
        return response


class Message:
    @staticmethod
    def generate_message(grantor: str, usernames: List[str], role_arn: str, time_window: GrantTimeWindow) -> str:
        grantees = ", ".join(usernames)
        message = (
            f"Temporary access to {role_arn} between {time_window.start_time} and {time_window.end_time} "
            f"has been granted to the following users by {grantor}: {grantees}"
        )
        return message
