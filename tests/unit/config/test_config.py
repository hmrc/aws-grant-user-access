from aws_grant_user_access.src.data.exceptions import InvalidConfigException, MissingConfigException
import pytest
from typing import Any
from unittest.mock import Mock, patch
from aws_grant_user_access.src.clients.slack_client import SlackClient
from aws_grant_user_access.src.config.config import Config


def test_get_default_log_level(monkeypatch: Any) -> None:
    monkeypatch.delenv("LOG_LEVEL", raising=False)

    assert Config.get_log_level() == "WARNING"


def test_get_invalid_log_level(monkeypatch: Any) -> None:
    monkeypatch.setenv("LOG_LEVEL", "PANIC")
    with pytest.raises(InvalidConfigException) as ice:
        Config.get_log_level()

    assert str(ice.value) == "invalid LOG_LEVEL: PANIC"


def test_get_slack_channels(monkeypatch: Any) -> None:
    monkeypatch.setenv("SLACK_CHANNELS", "#a-channel,#another-channel")

    assert Config().get_slack_channels() == ["#a-channel", "#another-channel"]


def test_get_slack_channels_missing(monkeypatch: Any) -> None:
    monkeypatch.delenv("SLACK_CHANNELS", raising=False)
    with pytest.raises(MissingConfigException):
        Config().get_slack_channels()


@patch("aws_grant_user_access.src.config.config.AwsClientFactory")
def test_get_slack_client(_mock_client_factory: Mock) -> None:
    ssm_client = _mock_client_factory.return_value.get_ssm_client.return_value
    ssm_client.get_parameter.return_value = "a-slack-api-key"

    slack_client = Config().get_slack_client()

    ssm_client.get_parameter.assert_called_once_with("/service_accounts/slack_v2_api_key")
    assert isinstance(slack_client, SlackClient)
