import boto3
from aws_grant_user_access.src.expired_policy_cleaner import ExpiredPolicyCleaner
from aws_grant_user_access.src.policy_creator import PolicyCreator
from datetime import datetime, timedelta
from moto import mock_iam


@mock_iam
def test_expired_policies_are_removed():
    expired_policy_cleaner = ExpiredPolicyCleaner()
    policy_creator = PolicyCreator()

    moto_client = boto3.client("iam")
    test_role_arn = "arn:aws:iam::123456789012:role/RoleUserAccess"
    test_username = "test-user"

    create_user_response = moto_client.create_user(
        UserName=test_username,
        PermissionsBoundary="engineering-boundary",
    )

    # Create an expired policy
    policy_creator.grant_access(
        role_arn=test_role_arn,
        username=create_user_response["User"].get("UserName"),
        start_time=datetime.utcnow() - timedelta(days=2),
        end_time=datetime.utcnow() - timedelta(days=1),
    )

    # Create a valid policy
    policy_creator.grant_access(
        role_arn=test_role_arn,
        username=create_user_response["User"].get("UserName"),
        start_time=datetime.utcnow(),
        end_time=datetime.utcnow() + timedelta(hours=1),
    )

    # Assert only valid policies exist
    policies = moto_client.list_policies(PathPrefix="/Lambda/GrantUserAccess/")["Policies"]

    assert len(policies) == 1
