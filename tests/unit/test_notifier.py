import json
from aws_grant_user_access.src.clients.aws_sns_client import AwsSnsClient
from aws_grant_user_access.src.data.data import AWS_REGION
from aws_grant_user_access.src.notifier import SNSMessagePublisher, SNSMessage
from aws_grant_user_access.src.grant_time_window import GrantTimeWindow
import boto3

from moto import mock_sns, mock_s3
from moto.core import DEFAULT_ACCOUNT_ID
from moto.sns import sns_backends
from datetime import datetime, timedelta
from freezegun import freeze_time


TEST_ROLE_ARN = "arn:aws:iam::123456789012:role/RoleUserAccess"
TEST_USERS = ["test-user-1", "test-user-2", "test-user-3"]
TEST_SNS_MESSAGE = {
    "detailType": "GrantUserAccessLambda",
    "account": "123456789012",
    "region": "eu-west-2",
    "roleArn": TEST_ROLE_ARN,
    "grantor": "approval.user",
    "usernames": TEST_USERS,
    "hours": 1,
    "startTime": "2012-01-14T12:00:01Z",
    "endTime": "2012-01-14T13:00:01Z",
}


sns_backend = sns_backends[DEFAULT_ACCOUNT_ID][AWS_REGION]


@mock_sns  # type: ignore
def test_publish_sns_message() -> None:
    moto_client = boto3.client("sns", region_name=AWS_REGION)
    sns_topic_arn = moto_client.create_topic(Name="grant-user-access-topic")["TopicArn"]
    response = SNSMessagePublisher(AwsSnsClient(moto_client)).publish_sns_message(
        sns_topic_arn=sns_topic_arn, message=json.dumps(TEST_SNS_MESSAGE)
    )

    assert isinstance(response, dict)
    message_id = response.get("MessageId", None)
    assert isinstance(message_id, str)

    all_send_notifications = sns_backend.topics[sns_topic_arn].sent_notifications
    assert all_send_notifications[0][1] == json.dumps(TEST_SNS_MESSAGE)


@freeze_time("2012-01-14 12:00:01")
def test_sns_message_to_dict() -> None:
    role_arn = "RoleArn"
    grantor = "super.user01"
    usernames = ["test.user01", "test.user02"]
    message = {
        "detailType": "GrantUserAccessLambda",
        "account": "123456789012",
        "region": "eu-west-2",
        "roleArn": "arn:aws:iam::123456789012:role/RoleUserAccess",
        "grantor": "super.user01",
        "usernames": ["test.user01", "test.user02"],
        "hours": 2,
        "startTime": "2012-01-14T12:00:01Z",
        "endTime": "2012-01-14T14:00:01Z",
    }

    assert (
        SNSMessage(
            account="123456789012",
            region="eu-west-2",
            role_arn="arn:aws:iam::123456789012:role/RoleUserAccess",
            grantor="super.user01",
            usernames=["test.user01", "test.user02"],
            hours=2,
            time_window=GrantTimeWindow(hours=2),
        ).to_dict()
        == message
    )
