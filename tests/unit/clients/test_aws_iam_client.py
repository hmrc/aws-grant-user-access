from aws_grant_user_access.src.data.exceptions import AwsClientException
import pytest
from unittest.mock import Mock

from aws_grant_user_access.src.clients.aws_iam_client import AwsIamClient
from botocore.exceptions import BotoCoreError


def test_create_policy() -> None:
    mock_client = Mock(create_policy=Mock(return_value={"Policy": {"Arn": "aws::policy/test_policy"}}))
    arn = AwsIamClient(mock_client).create_policy(
        policy_name="test_policy", path="path", policy_document="{}", description="description", tags=[]
    )

    assert arn == "aws::policy/test_policy"


def test_create_policy_failure() -> None:
    mock_client = Mock(create_policy=Mock(side_effect=BotoCoreError()))
    with pytest.raises(AwsClientException) as ace:
        arn = AwsIamClient(mock_client).create_policy(
            policy_name="test_policy", path="path", policy_document="{}", description="description", tags=[]
        )

    assert str(ace.value) == "failed to create policy test_policy: An unspecified error occurred"


def test_attach_user_policy() -> None:
    mock_client = Mock()
    AwsIamClient(mock_client).attach_user_policy(username="test.user", policy_arn="aws::policy/test_policy")
    mock_client.attach_user_policy.assert_called_once_with(UserName="test.user", PolicyArn="aws::policy/test_policy")


def test_list_policies() -> None:
    mock_client = Mock()
    AwsIamClient(mock_client).list_policies(path_prefix="/lambda/grant_user_access")
    mock_client.list_policies.assert_called_once_with(PathPrefix="/lambda/grant_user_access")


def test_get_policy() -> None:
    mock_client = Mock()
    AwsIamClient(mock_client).get_policy(policy_arn="aws::policy/test_policy")
    mock_client.get_policy.assert_called_once_with(PolicyArn="aws::policy/test_policy")


def test_detach_user_policy() -> None:
    mock_client = Mock()
    AwsIamClient(mock_client).detach_user_policy(username="test.user", policy_arn="aws::policy/test_policy")
    mock_client.detach_user_policy.assert_called_once_with(UserName="test.user", PolicyArn="aws::policy/test_policy")


def test_delete_policy() -> None:
    mock_client = Mock()
    AwsIamClient(mock_client).delete_policy(policy_arn="aws::policy/test_policy")
    mock_client.delete_policy.assert_called_once_with(PolicyArn="aws::policy/test_policy")


def test_list_attached_user_policies() -> None:
    mock_client = Mock(list_attached_user_policies=Mock(return_value={"AttachedPolicies": []}))
    AwsIamClient(mock_client).list_attached_user_policies(username="test.user", path_prefix="/lambda/grant_user_access")
    mock_client.list_attached_user_policies.assert_called_once_with(
        UserName="test.user", PathPrefix="/lambda/grant_user_access"
    )

def test_get_user() -> None:
    mock_client = Mock()
    AwsIamClient(mock_client).get_user(user_name="test-user-1")
    mock_client.get_user.assert_called_once_with(UserName="test-user-1")

def test_get_role() -> None:
    mock_client = Mock()
    AwsIamClient(mock_client).get_role(role_name="role_engineer_user_access")
    mock_client.get_role.assert_called_once_with(RoleName="role_engineer_user_access")

def test_list_groups_for_user() -> None:
    mock_client = Mock()
    AwsIamClient(mock_client).list_groups_for_user(user_name="test-engineer-1")
    mock_client.list_groups_for_user.assert_called_once_with(UserName="test-engineer-1")