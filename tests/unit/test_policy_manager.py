from datetime import datetime, UTC, timedelta
from unittest.mock import Mock

import boto3
from freezegun import freeze_time
from moto import mock_iam

from aws_grant_user_access.src.policy_manager import PolicyCreator

GET_POLICY = {
    "Policy": {
        "PolicyName": "test-user-3_1693482856.642057",
        "PolicyId": "ABCDEFGHIJKLMNOP01234",
        "Arn": "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057",
        "Path": "/Lambda/GrantUserAccess/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 1,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": "true",
        "Description": "An IAM policy to grant-user-access to assume a role",
        "CreateDate": "2020-05-01T00:00:00+00:00",
        "UpdateDate": "2020-05-01T00:00:00+00:00",
        "Tags": [
            {"Key": "Expires_At", "Value": "2020-05-02T00:00:00+00:00"},
            {"Key": "Product", "Value": "grant-user-access"},
        ],
    }
}

LIST_POLICIES = {
    "Policies": [
        {
            "PolicyName": "test-user-3_1693482856.642057",
            "Arn": "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057",
            "DefaultVersionId": "foo",
            "Tags": [
                {"Key": "Expires_At", "Value": "2020-05-01T00:00:00Z"},
                {"Key": "Product", "Value": "grant-user-access"},
            ],
        },
        {
            "Arn": "to_keep",
            "DefaultVersionId": "foo",
            "Tags": [
                {"Key": "Expires_At", "Value": "2023-05-01T00:00:00Z"},
                {"Key": "Product", "Value": "grant-user-access"},
            ],
        },
        {
            "Arn": "to_keep_2",
            "DefaultVersionId": "foo",
            "Tags": [
                {"Key": "Expires_At", "Value": "2023-05-01T00:00:00Z"},
            ],
        },
        {
            "PolicyName": "to-delete-also.1693482856.642057",
            "Arn": "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/to-delete-also.1693482856.642057",
            "DefaultVersionId": "foo",
            "Tags": [
                {"Key": "Expires_At", "Value": "2021-01-01T01:01:00Z"},
                {"Key": "Product", "Value": "grant-user-access"},
            ],
        },
    ],
}


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
        UserName="test-user-2",
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
    assert policies[0]["PolicyName"] == f"test-user-2_{start_time.timestamp()}"

    expected_policy_arn = (
        f"arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-2_{start_time.timestamp()}"
    )

    response = moto_client.list_attached_user_policies(PathPrefix="/Lambda/GrantUserAccess/", UserName="test-user-2")
    assert expected_policy_arn == response["AttachedPolicies"][0]["PolicyArn"]


def test_policy_is_tagged_with_expiry_time():
    # using a hand rolled mock here as moto does not return back policy tags
    mock_client = Mock(create_policy=Mock(return_value={"Policy": {"test": "example"}}))

    end_time = datetime(year=2012, month=1, day=15, hour=0, minute=0, second=1)

    PolicyCreator(mock_client).grant_access(
        role_arn="arn:aws:iam::123456789012:role/somerole",
        username="test-user-2",
        start_time=datetime.utcnow(),
        end_time=end_time,
    )

    mock_client.create_policy.assert_called_once()
    assert mock_client.create_policy.call_args.kwargs["Tags"] == [
        {"Key": "Product", "Value": "grant-user-access"},
        {"Key": "Expires_At", "Value": "2012-01-15T00:00:01Z"},
    ]


def test_find_expired_policies_returns_arns_of_no_longer_needed_policies():
    # using a hand rolled mock here as moto does not return back policy tags
    mock_client = Mock(list_policies=Mock(return_value=LIST_POLICIES))

    expired = PolicyCreator(mock_client).find_expired_policies(
        current_time=datetime(year=2021, month=1, day=1, hour=1, minute=1, second=1)
    )

    mock_client.list_policies.assert_called_once_with(PathPrefix="/Lambda/GrantUserAccess/")

    assert expired == [
        "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057",
        "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/to-delete-also.1693482856.642057",
    ]


# def test_get_policy_name():
#     mock_client = Mock(get_policy=Mock(return_value=GET_POLICY))
#
#     policy_name = PolicyCreator(mock_client).get_policy_name(
#         policy_arn="arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057"
#     )
#     assert policy_name == "test-user-3_1693482856.642057"


# def test_detach_expired_policies_from_users():
#     mock_client = Mock(
#         list_policies=Mock(return_value=LIST_POLICIES),
#         get_policy=Mock(return_value=GET_POLICY),
#         detach_user_policy=Mock(),
#     )
#
#     PolicyCreator(mock_client).detach_expired_policies_from_users(
#         current_time=datetime(year=2021, month=1, day=1, hour=1, minute=1, second=1)
#     )
#
#     mock_client.detach_user_policy.assert_any_call(
#         UserName="test-user-3",
#         PolicyArn="arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057",
#     )
#
#     assert 2 == mock_client.detach_user_policy.call_count


# def test_delete_expired_policies():
#     mock_client = Mock(
#         list_policies=Mock(return_value=LIST_POLICIES),
#         get_policy=Mock(return_value=GET_POLICY),
#         delete_policy=Mock(),
#     )
#
#     PolicyCreator(mock_client).delete_expired_policies(
#         current_time=datetime(year=2021, month=1, day=1, hour=1, minute=1, second=1)
#     )
#
#     mock_client.delete_policy.assert_any_call(
#         PolicyArn="arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057"
#     )
#
#     assert 2 == mock_client.delete_policy.call_count
