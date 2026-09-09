from aws_grant_user_access.src.data.exceptions import AwsClientException
import pytest
from unittest.mock import Mock

from aws_grant_user_access.src.clients.aws_ssm_client import AwsSsmClient
from botocore.exceptions import BotoCoreError


def test_get_parameter() -> None:
    mock_client = Mock(get_parameter=Mock(return_value={"Parameter": {"Value": "a-secret-value"}}))
    response = AwsSsmClient(mock_client).get_parameter(name="/a/parameter/name")
    mock_client.get_parameter.assert_called_once_with(Name="/a/parameter/name", WithDecryption=True)

    assert response == "a-secret-value"


def test_get_parameter_failure() -> None:
    mock_client = Mock(get_parameter=Mock(side_effect=BotoCoreError()))
    with pytest.raises(AwsClientException) as ace:
        AwsSsmClient(mock_client).get_parameter(name="/a/parameter/name")

    assert str(ace.value) == "failed to get parameter /a/parameter/name: An unspecified error occurred"
