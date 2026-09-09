from typing import Any, Dict, List
from aws_grant_user_access.src.clients.aws_sns_client import AwsSnsClient
from aws_grant_user_access.src.clients.slack_client import SlackClient
from aws_grant_user_access.src.data.data import AWS_IAM_TIME_FORMAT

from aws_grant_user_access.src.grant_time_window import GrantTimeWindow

SLACK_DISPLAY_NAME = "grant-user-access"
SLACK_EMOJI = ":unlock:"


class SNSMessage:
    def __init__(
        self,
        account: str,
        region: str,
        role_arn: str,
        usernames: List[str],
        hours: int,
        time_window: GrantTimeWindow,
    ) -> None:
        self.account = account
        self.region = region
        self.role_arn = role_arn
        self.usernames = usernames
        self.hours = hours
        self.time_window = time_window

    def to_dict(self) -> Dict[str, Any]:
        return {
            "detailType": "GrantUserAccessLambda",
            "account": self.account,
            "region": self.region,
            "roleArn": self.role_arn,
            "usernames": self.usernames,
            "hours": self.hours,
            "startTime": self.time_window.start_time.strftime(AWS_IAM_TIME_FORMAT),
            "endTime": self.time_window.end_time.strftime(AWS_IAM_TIME_FORMAT),
        }


class SNSMessagePublisher:
    def __init__(self, sns_client: AwsSnsClient) -> None:
        self.sns_client = sns_client

    def publish_sns_message(self, sns_topic_arn: str, message: str) -> Dict[str, str]:
        return self.sns_client.publish(sns_topic_arn=sns_topic_arn, message=message)


class SlackMessage:
    def __init__(
        self,
        role_arn: str,
        usernames: List[str],
        hours: int,
        time_window: GrantTimeWindow,
    ) -> None:
        self.role_arn = role_arn
        self.usernames = usernames
        self.hours = hours
        self.time_window = time_window

    def text(self) -> str:
        start_time = self.time_window.start_time.strftime(AWS_IAM_TIME_FORMAT)
        end_time = self.time_window.end_time.strftime(AWS_IAM_TIME_FORMAT)
        users = "\n".join(f"  *  {username}" for username in self.usernames)
        return (
            "Temporary access to user(s) granted\n"
            f"Access to `{self.role_arn}` has been granted for {self.hours} hour(s) "
            f"to the following users at {start_time}:\n"
            f"{users}\n"
            f"Access expires at {end_time}."
        )


class SlackMessagePublisher:
    def __init__(self, slack_client: SlackClient) -> None:
        self.slack_client = slack_client

    def publish_slack_message(self, channels: List[str], message: SlackMessage) -> Dict[str, Any]:
        return self.slack_client.post(
            channels=channels, display_name=SLACK_DISPLAY_NAME, emoji=SLACK_EMOJI, text=message.text()
        )
