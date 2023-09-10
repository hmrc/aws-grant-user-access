from aws_grant_user_access.src.data.exceptions import AwsClientException
import pytest
from unittest.mock import Mock

from aws_grant_user_access.src.clients.aws_sns_client import AwsSnsClient
from botocore.exceptions import BotoCoreError, ClientError


def test_publish() -> None:
    mock_client = Mock(publish=Mock(return_value={"MessageId": "a_message_id"}))
    response = AwsSnsClient(mock_client).publish(sns_topic_arn="test_topic_arn", message="a test message")
    mock_client.publish.assert_called_once_with(TopicArn="test_topic_arn", Message="a test message")

    assert isinstance(response, dict)


def test_publish_failure() -> None:
    mock_client = Mock(publish=Mock(side_effect=BotoCoreError()))
    with pytest.raises(AwsClientException) as ace:
        response = AwsSnsClient(mock_client).publish(sns_topic_arn="test_topic_arn", message="a test message")

    assert str(ace.value) == "failed to publish a message to test_topic_arn: An unspecified error occurred"
