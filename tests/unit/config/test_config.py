from aws_grant_user_access.src.data.exceptions import AwsClientException, InvalidConfigException, MissingConfigException
import pytest
from typing import Any
from unittest.mock import Mock, patch
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
@patch("aws_grant_user_access.src.config.config.SlackClient")
def test_get_slack_client(mock_slack_client: Mock, mock_client_factory: Mock, monkeypatch: Any) -> None:
    secret_arn = "arn:aws:secretsmanager:eu-west-2:111111111111:secret:slack-AbCdEf"
    monkeypatch.setenv("SLACK_API_SECRET_ARN", secret_arn)
    secrets_client = mock_client_factory.return_value.get_secrets_manager_client.return_value
    secrets_client.get_secret_value.return_value = "a-slack-api-key"

    slack_client = Config().get_slack_client()

    secrets_client.get_secret_value.assert_called_once_with(secret_arn)
    mock_slack_client.assert_called_once_with(
        webhook_url="https://slack-notifications.tax.service.gov.uk/api/v2/notification",
        api_key="a-slack-api-key",
    )
    assert slack_client is mock_slack_client.return_value


@patch("aws_grant_user_access.src.config.config.AwsClientFactory")
@patch("aws_grant_user_access.src.config.config.SlackClient")
def test_get_slack_client_missing_secret_arn(
    mock_slack_client: Mock, mock_client_factory: Mock, monkeypatch: Any
) -> None:
    monkeypatch.delenv("SLACK_API_SECRET_ARN", raising=False)

    with pytest.raises(MissingConfigException, match="SLACK_API_SECRET_ARN"):
        Config().get_slack_client()

    mock_client_factory.assert_not_called()
    mock_slack_client.assert_not_called()


@patch("aws_grant_user_access.src.config.config.AwsClientFactory")
@patch("aws_grant_user_access.src.config.config.SlackClient")
def test_get_slack_client_secret_failure(mock_slack_client: Mock, mock_client_factory: Mock, monkeypatch: Any) -> None:
    monkeypatch.setenv("SLACK_API_SECRET_ARN", "a-secret-arn")
    secrets_client = mock_client_factory.return_value.get_secrets_manager_client.return_value
    error = AwsClientException("failed to retrieve secret")
    secrets_client.get_secret_value.side_effect = error

    with pytest.raises(AwsClientException) as ace:
        Config().get_slack_client()

    assert ace.value is error
    secrets_client.get_secret_value.assert_called_once_with("a-secret-arn")
    mock_slack_client.assert_not_called()


@pytest.mark.parametrize("value,expected", [("true", True), ("TRUE", True), ("false", False), ("False", False)])
def test_is_dry_run(monkeypatch: Any, value: str, expected: bool) -> None:
    monkeypatch.setenv("DRY_RUN", value)

    assert Config.is_dry_run() is expected


def test_is_dry_run_defaults_to_false(monkeypatch: Any) -> None:
    monkeypatch.delenv("DRY_RUN", raising=False)

    assert Config.is_dry_run() is False


def test_is_dry_run_invalid(monkeypatch: Any) -> None:
    monkeypatch.setenv("DRY_RUN", "yes")
    with pytest.raises(InvalidConfigException) as ice:
        Config.is_dry_run()

    assert str(ice.value) == "invalid DRY_RUN: yes"
