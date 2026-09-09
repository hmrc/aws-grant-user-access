import json
from unittest.mock import Mock, patch

import pytest
import requests

from aws_grant_user_access.src.clients.slack_client import SlackClient
from aws_grant_user_access.src.data.exceptions import SlackNotificationException


@patch("aws_grant_user_access.src.clients.slack_client.requests.post")
def test_post(_mock_post: Mock) -> None:
    _mock_post.return_value = Mock(json=Mock(return_value={}))

    response = SlackClient(webhook_url="https://slack-notifications.example/api/v2/notification", api_key="a-key").post(
        channels=["#a-channel"], display_name="grant-user-access", emoji=":unlock:", text="a message"
    )

    _mock_post.assert_called_once_with(
        url="https://slack-notifications.example/api/v2/notification",
        data=json.dumps(
            {
                "channelLookup": {"by": "slack-channel", "slackChannels": ["#a-channel"]},
                "displayName": "grant-user-access",
                "emoji": ":unlock:",
                "text": "a message",
            }
        ),
        headers={"Content-Type": "application/json", "Authorization": "a-key"},
        timeout=10,
    )
    assert response == {}


@patch("aws_grant_user_access.src.clients.slack_client.requests.post")
def test_post_request_failure(_mock_post: Mock) -> None:
    _mock_post.side_effect = requests.RequestException("boom")

    with pytest.raises(SlackNotificationException) as sne:
        SlackClient(webhook_url="https://slack-notifications.example/api/v2/notification", api_key="a-key").post(
            channels=["#a-channel"], display_name="grant-user-access", emoji=":unlock:", text="a message"
        )

    assert str(sne.value) == "failed to post message to slack channels ['#a-channel']: boom"


@patch("aws_grant_user_access.src.clients.slack_client.requests.post")
def test_post_slack_rejects_message(_mock_post: Mock) -> None:
    _mock_post.return_value = Mock(json=Mock(return_value={"errors": ["channel not found"]}))

    with pytest.raises(SlackNotificationException) as sne:
        SlackClient(webhook_url="https://slack-notifications.example/api/v2/notification", api_key="a-key").post(
            channels=["#a-channel"], display_name="grant-user-access", emoji=":unlock:", text="a message"
        )

    assert str(sne.value) == "slack rejected message to channels ['#a-channel']: ['channel not found']"
