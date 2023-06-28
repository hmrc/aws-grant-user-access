from datetime import datetime, UTC, timedelta
from unittest.mock import Mock

import boto3
from moto import mock_iam

from aws_grant_user_access.src.policy_creator import PolicyCreator


def test_policy_creator_generates_policy_document():
    policy_document = PolicyCreator.generate_policy_document(
        role_arn="aws:::test",
        start_time=datetime(year=2020, month=5, day=1, hour=0, minute=0, second=0, tzinfo=UTC),
        end_time=datetime(year=2020, month=5, day=1, hour=23, minute=59, second=59, tzinfo=UTC),
    )

    expected_result = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "sts:AssumeRole",
                "Resource": "aws:::test",
                "Condition": {
                    "DateGreaterThan": {"aws:CurrentTime": "2020-05-01T00:00:00Z"},
                    "DateLessThan": {"aws:CurrentTime": "2020-05-01T23:59:59Z"},
                },
            }
        ],
    }

    assert policy_document == expected_result


@mock_iam
def test_policy_creator_creates_policy_document():
    moto_client = boto3.client("iam")

    policy_creator = PolicyCreator(moto_client)

    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {"Effect": "Allow", "Action": "sts:AssumeRole", "Resource": "arn:aws:iam::123456789012:role/somerole"}
        ],
    }
    policy_creator.create_iam_policy(policy_document=policy, name="some_name", end_time=datetime.utcnow())

    policies = moto_client.list_policies(PathPrefix="/Lambda/GrantUserAccess/")["Policies"]
    assert len(policies) == 1
    assert policies[0]["PolicyName"] == "some_name"


@mock_iam
def test_policy_creator_grants_access():
    moto_client = boto3.client("iam")
    policy_creator = PolicyCreator(moto_client)
    start_time = datetime.utcnow()
    role_arn = "arn:aws:iam::123456789012:role/somerole"

    create_user_response = moto_client.create_user(
        UserName="test-user",
        PermissionsBoundary="engineering-boundary",
    )

    policy_creator.grant_access(
        role_arn=role_arn,
        username=create_user_response["User"].get("UserName"),
        start_time=start_time,
        end_time=start_time,
    )

    policies = moto_client.list_policies(PathPrefix="/Lambda/GrantUserAccess")["Policies"]
    assert len(policies) == 1
    assert policies[0]["PolicyName"] == f"test-user_{start_time.timestamp()}"

    expected_policy_arn = f"arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user_{start_time.timestamp()}"

    response = moto_client.list_attached_user_policies(PathPrefix="/Lambda/GrantUserAccess/", UserName="test-user")
    assert expected_policy_arn == response["AttachedPolicies"][0]["PolicyArn"]


def test_policy_is_tagged_with_expiry_time():
    mock_client = Mock(create_policy=Mock(return_value={"Policy": {"test":"example"}}))

    end_time = datetime(year=2012, month=1, day=15, hour=0, minute=0, second=1)

    PolicyCreator(mock_client).grant_access(
        role_arn="arn:aws:iam::123456789012:role/somerole",
        username="test-user",
        start_time=datetime.utcnow(),
        end_time=end_time
    )

    mock_client.create_policy.assert_called_once()
    assert mock_client.create_policy.call_args.kwargs["Tags"] == [
        {'Key': 'Product', 'Value': 'grant-user-access'},
        {'Key': 'Expires_At', 'Value': "1326585601.0"}
    ]