import json
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
    "roleArn": TEST_ROLE_ARN,
    "grantor": "",
    "usernames": TEST_USERS,
    "startTime": "2012-01-14T12:00:01Z",
    "endTime": "2012-01-14T13:00:01Z",
}


sns_backend = sns_backends[DEFAULT_ACCOUNT_ID][AWS_REGION]


@mock_sns
def test_publish_sns_message():
    mock_client = boto3.client("sns", region_name=AWS_REGION)
    sns_topic_arn = mock_client.create_topic(Name="grant-user-access-topic")["TopicArn"]
    publisher = SNSMessagePublisher(mock_client)
    response = publisher.publish_sns_message(sns_topic_arn=sns_topic_arn, message=json.dumps(TEST_SNS_MESSAGE))

    assert isinstance(response, dict)
    message_id = response.get("MessageId", None)
    assert isinstance(message_id, str)

    all_send_notifications = sns_backend.topics[sns_topic_arn].sent_notifications
    assert all_send_notifications[0][1] == json.dumps(TEST_SNS_MESSAGE)


@freeze_time("2012-06-27 12:00:01")
def test_generate_message():
    role_arn = "RoleArn"
    grantor = "super.user01"
    usernames = ["test.user01", "test.user02"]
    message = {
        "detailType": "GrantUserAccessLambda",
        "roleArn": role_arn,
        "grantor": grantor,
        "usernames": usernames,
        "startTime": "2012-06-27T12:00:01Z",
        "endTime": "2012-06-27T14:00:01Z",
    }

    assert (
        SNSMessage.generate(
            grantor=grantor, usernames=usernames, role_arn=role_arn, time_window=GrantTimeWindow(hours=2)
        )
        == message
    )
