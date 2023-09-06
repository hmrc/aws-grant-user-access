from aws_grant_user_access.src.notifier import SNSMessagePublisher, Message
from aws_grant_user_access.src.grant_time_window import GrantTimeWindow
import boto3

from moto import mock_sns, mock_s3
from moto.core import DEFAULT_ACCOUNT_ID
from moto.sns import sns_backends
from datetime import datetime, timedelta
from freezegun import freeze_time


sns_backend = sns_backends[DEFAULT_ACCOUNT_ID]["eu-west-2"]


@mock_sns
def test_publish_sns_message():
    mock_client = boto3.client("sns", region_name="eu-west-2")
    topic_arn = mock_client.create_topic(Name="grant-user-access-topic")["TopicArn"]
    publisher = SNSMessagePublisher(mock_client)
    response = publisher.publish_sns_message(topic_arn=topic_arn, message="a message from the future")

    assert isinstance(response, dict)
    message_id = response.get("MessageId", None)
    assert isinstance(message_id, str)

    all_send_notifications = sns_backend.topics[topic_arn].sent_notifications
    assert all_send_notifications[0][1] == "a message from the future"


@freeze_time("2012-06-27 12:00:01")
def test_generate_message():
    role_arn = "RoleArn"
    grantor = "super.user01"
    usernames = ["test.user01", "test.user02"]
    start_time = datetime(year=2012, month=6, day=27, hour=12, minute=0, second=1)
    end_time = datetime(year=2012, month=6, day=27, hour=14, minute=0, second=1)
    message = f"Temporary access to {role_arn} between {start_time} and {end_time} has been granted to the following users by {grantor}: {', '.join(usernames)}"

    assert (
        Message.generate_message(
            grantor=grantor, usernames=usernames, role_arn=role_arn, time_window=GrantTimeWindow(hours=2)
        )
        == message
    )
