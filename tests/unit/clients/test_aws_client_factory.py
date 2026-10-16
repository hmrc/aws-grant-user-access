from unittest.mock import Mock, patch

from aws_grant_user_access.src.clients.aws_client_factory import AwsClientFactory
from aws_grant_user_access.src.clients.aws_iam_client import AwsIamClient
from aws_grant_user_access.src.clients.aws_secrets_manager import AwsSecretsManagerClient
from aws_grant_user_access.src.data.data import AWS_REGION


def test_get_iam_client() -> None:
    iam_client = AwsClientFactory().get_iam_client()
    assert isinstance(iam_client, AwsIamClient)


def test_get_secrets_manager_client() -> None:
    mock_client = Mock(get_secret_value=Mock(return_value={"SecretString": "a-secret-value"}))
    with patch(
        "aws_grant_user_access.src.clients.aws_client_factory.boto3.client", return_value=mock_client
    ) as mock_boto_client:
        secrets_manager_client = AwsClientFactory().get_secrets_manager_client()

    assert isinstance(secrets_manager_client, AwsSecretsManagerClient)
    mock_boto_client.assert_called_once_with("secretsmanager", region_name=AWS_REGION)
    assert secrets_manager_client.get_secret_value("a-secret") == "a-secret-value"
    mock_client.get_secret_value.assert_called_once_with(SecretId="a-secret")
