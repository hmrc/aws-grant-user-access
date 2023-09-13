from datetime import datetime, UTC, timedelta
from unittest.mock import Mock, call
from aws_grant_user_access.src.clients.aws_iam_client import AwsIamClient
from typing import Any, Dict

import boto3
from freezegun import freeze_time
from moto import mock_iam

from aws_grant_user_access.src.policy_manager import PolicyCreator
import tests.unit.responses.test_iam_policies as resp


def test_policy_creator_generates_policy_document() -> None:
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


@mock_iam  # type: ignore
def test_policy_creator_creates_policy_document() -> None:
    moto_client = boto3.client("iam")

    policy_creator = PolicyCreator(AwsIamClient(moto_client))

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


@mock_iam  # type: ignore
def test_policy_creator_grants_access() -> None:
    moto_client = boto3.client("iam")
    policy_creator = PolicyCreator(AwsIamClient(moto_client))
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


def test_policy_is_tagged_with_expiry_time() -> None:
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
    assert mock_client.create_policy.call_args.kwargs["tags"] == [
        {"Key": "Product", "Value": "grant-user-access"},
        {"Key": "Expires_At", "Value": "2012-01-15T00:00:01Z"},
    ]


def _get_policy(policy_arn: str) -> Dict[str, Any]:
    return resp.POLICIES_MAP[policy_arn]


def _list_policies(path_prefix: str) -> Dict[str, Any]:
    valid_policies = [policy for policy in resp.LIST_POLICIES["Policies"] if path_prefix in policy["Arn"]]
    return {"Policies": valid_policies}


@mock_iam  # type: ignore
def test_find_expired_policies_returns_arns_of_no_longer_needed_policies() -> None:
    mock_client = Mock(
        list_policies=Mock(side_effect=_list_policies),
        get_policy=Mock(side_effect=_get_policy),
    )

    expired = PolicyCreator(mock_client).find_expired_policies(
        current_time=datetime(year=2021, month=1, day=1, hour=1, minute=1, second=1)
    )
    mock_client.list_policies.assert_called_once_with(path_prefix="/Lambda/GrantUserAccess/")
    mock_client.get_policy.assert_has_calls(
        [
            call(policy_arn="arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057"),
            call(policy_arn="arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-4_1693482856.642057"),
            call(policy_arn="arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/to_keep"),
        ],
        any_order=True,
    )

    assert expired == [
        "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057",
        "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-4_1693482856.642057",
    ]


def test_is_policy_expired_returns_true() -> None:
    mock_client = Mock(get_policy=Mock(side_effect=_get_policy))

    is_expired = PolicyCreator(mock_client).is_policy_expired(
        policy_arn="arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057",
        current_time=datetime(year=2021, month=1, day=1, hour=1, minute=1, second=1),
    )
    assert is_expired == True


def test_get_policy_name() -> None:
    mock_client = Mock(get_policy=Mock(side_effect=_get_policy))

    policy_name = PolicyCreator(mock_client).get_policy_name(
        policy_arn="arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057"
    )
    assert policy_name == "test-user-3_1693482856.642057"


def test_detach_expired_policies_from_users() -> None:
    mock_client = Mock(
        get_policy=Mock(side_effect=_get_policy),
        list_policies=Mock(side_effect=_list_policies),
        list_attached_user_policies=Mock(return_value=resp.LIST_ATTACHED_USER_POLICIES),
        detach_user_policy=Mock(),
    )

    PolicyCreator(mock_client).detach_expired_policies_from_users(
        current_time=datetime(year=2021, month=1, day=1, hour=1, minute=1, second=1)
    )

    mock_client.detach_user_policy.assert_any_call(
        username="test-user-3",
        policy_arn="arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057",
    )

    mock_client.detach_user_policy.assert_has_calls(
        [
            call(
                username="test-user-3",
                policy_arn="arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057",
            ),
            call(
                username="test-user-4",
                policy_arn="arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-4_1693482856.642057",
            ),
        ],
        any_order=True,
    )


def test_delete_expired_policies() -> None:
    mock_client = Mock(
        list_policies=Mock(return_value=resp.LIST_POLICIES),
        get_policy=Mock(side_effect=_get_policy),
        delete_policy=Mock(),
    )

    PolicyCreator(mock_client).delete_expired_policies(
        current_time=datetime(year=2021, month=1, day=1, hour=1, minute=1, second=1)
    )

    mock_client.delete_policy.assert_any_call(
        policy_arn="arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057"
    )

    assert 2 == mock_client.delete_policy.call_count


def test_get_attached_user_policy_arns():
    mock_client = Mock(
        list_attached_user_policies=Mock(return_value=resp.LIST_ATTACHED_USER_POLICIES),
    )

    arns = PolicyCreator(mock_client).get_attached_user_policy_arns(
        username="test.user", path_prefix="/Lambda/GrantUserAccess/"
    )
    mock_client.list_attached_user_policies.assert_called_once_with(
        username="test.user", path_prefix="/Lambda/GrantUserAccess/"
    )

    assert arns == [
        "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057",
        "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-4_1693482856.642057",
        "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/to_keep",
    ]
