from unittest.mock import Mock

import pytest
from botocore.exceptions import BotoCoreError, ClientError

from aws_grant_user_access.src.clients.aws_secrets_manager import AwsSecretsManagerClient
from aws_grant_user_access.src.data.exceptions import AwsClientException


@pytest.mark.parametrize(
    "secret_id",
    ["service_accounts/slack_v2_api_key", "arn:aws:secretsmanager:eu-west-2:111111111111:secret:slack-AbCdEf"],
)
@pytest.mark.parametrize("secret_string", ["a-secret-value", '{"token": "a-secret-value"}', ""])
def test_get_secret_value(secret_id: str, secret_string: str) -> None:
    mock_client = Mock(get_secret_value=Mock(return_value={"SecretString": secret_string}))

    assert AwsSecretsManagerClient(mock_client).get_secret_value(secret_id) == secret_string
    mock_client.get_secret_value.assert_called_once_with(SecretId=secret_id)


def test_get_secret_value_failure() -> None:
    mock_client = Mock(get_secret_value=Mock(side_effect=BotoCoreError()))

    with pytest.raises(AwsClientException) as ace:
        AwsSecretsManagerClient(mock_client).get_secret_value("a-secret")

    assert str(ace.value) == "failed to get secret a-secret: An unspecified error occurred"


def test_get_secret_value_client_error() -> None:
    error = ClientError({"Error": {"Code": "AccessDeniedException", "Message": "Access denied"}}, "GetSecretValue")
    mock_client = Mock(get_secret_value=Mock(side_effect=error))

    with pytest.raises(AwsClientException) as ace:
        AwsSecretsManagerClient(mock_client).get_secret_value("a-secret")

    assert str(ace.value) == f"failed to get secret a-secret: {error}"


@pytest.mark.parametrize("response", [{"SecretBinary": b"binary-secret"}, {}, {"SecretString": None}])
def test_get_secret_value_rejects_non_string_secret(response: dict[str, object]) -> None:
    mock_client = Mock(get_secret_value=Mock(return_value=response))

    with pytest.raises(AwsClientException) as ace:
        AwsSecretsManagerClient(mock_client).get_secret_value("a-secret")

    assert str(ace.value) == "failed to get secret a-secret: expected a string secret"
