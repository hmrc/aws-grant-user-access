from aws_grant_user_access.src.clients.aws_client_factory import AwsClientFactory
from aws_grant_user_access.src.clients.aws_iam_client import AwsIamClient
from aws_grant_user_access.src.clients.aws_sns_client import AwsSnsClient
from aws_grant_user_access.src.clients.aws_ssm_client import AwsSsmClient


def test_get_iam_client() -> None:
    iam_client = AwsClientFactory().get_iam_client()
    assert isinstance(iam_client, AwsIamClient)


def test_get_sns_client() -> None:
    sns_client = AwsClientFactory().get_sns_client()
    assert isinstance(sns_client, AwsSnsClient)


def test_get_ssm_client() -> None:
    ssm_client = AwsClientFactory().get_ssm_client()
    assert isinstance(ssm_client, AwsSsmClient)
