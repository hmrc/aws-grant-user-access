from datetime import datetime, timedelta
import json
import os
import boto3
from moto import mock_iam
from unittest.mock import Mock, patch
from aws_grant_user_access.src.grant_time_window import GrantTimeWindow
from aws_grant_user_access.src.notifier import SNSMessage
from aws_grant_user_access.src.process_event import process_event, publish_sns_message, PERMITTED_ROLES
from typing import Any
from freezegun import freeze_time


TEST_ROLE_ARN = "arn:aws:iam::123456789012:role/RoleEngineerUserAccess"
TEST_PO_ROLE_ARN = "arn:aws:iam::123456789012:role/RolePlatformOwnerUserAccess"
TEST_USERS = ["test-user-1", "test-user-2", "test-user-3"]
TEST_SNS_MESSAGE = {
    "detailType": "GrantUserAccessLambda",
    "account": "123456789012",
    "region": "eu-west-2",
    "roleArn": TEST_ROLE_ARN,
    "usernames": TEST_USERS,
    "hours": 1,
    "startTime": "2012-01-14T12:00:01Z",
    "endTime": "2012-01-14T13:00:01Z",
}


@mock_iam
def _mock_users_and_group(usernames: Any, groupname: Any) -> None:
    moto_client = boto3.client("iam")

    moto_client.create_group(Path="/", GroupName=groupname)

    for username in usernames:
        moto_client.create_user(UserName=username)
        moto_client.add_user_to_group(GroupName=groupname, UserName=username)


@freeze_time("2012-01-14 12:00:01")
@patch("aws_grant_user_access.src.process_event.PolicyCreator")
@mock_iam
def test_process_event_creates_iam_policy(_mock_policy_creator: Mock) -> None:
    _mock_users_and_group(TEST_USERS, "test_platform_engineer")

    context = Mock()
    context.invoked_function_arn = "arn:aws:lambda:eu-west-2:123456789012:function:grant-user-access"

    policy_creator = _mock_policy_creator.return_value
    policy_creator.grant_access.return_value = Mock()
    process_event(dict(role_arn=TEST_ROLE_ARN, usernames=TEST_USERS, approval_in_hours=12), context)

    assert 3 == policy_creator.grant_access.call_count

    policy_creator.grant_access.assert_any_call(
        role_arn=TEST_ROLE_ARN,
        username=TEST_USERS[1],
        start_time=datetime(year=2012, month=1, day=14, hour=12, minute=0, second=1),
        end_time=datetime(year=2012, month=1, day=15, hour=0, minute=0, second=1),
    )

    policy_creator.grant_access.assert_any_call(
        role_arn=TEST_ROLE_ARN,
        username=TEST_USERS[0],
        start_time=datetime(year=2012, month=1, day=14, hour=12, minute=0, second=1),
        end_time=datetime(year=2012, month=1, day=15, hour=0, minute=0, second=1),
    )


@freeze_time("2012-01-14 12:00:01")
@patch("aws_grant_user_access.src.process_event.PolicyCreator")
@mock_iam
def test_process_event_deletes_expired_policies(_mock_policy_creator: Mock) -> None:
    context = Mock()
    context.invoked_function_arn = "arn:aws:lambda:eu-west-2:123456789012:function:grant-user-access"

    _mock_users_and_group(TEST_USERS, "test_platform_engineer")

    policy_creator = _mock_policy_creator.return_value
    policy_creator.delete_expired_policies.return_value = Mock()
    process_event(dict(role_arn=TEST_ROLE_ARN, usernames=TEST_USERS, approval_in_hours=12), context)

    policy_creator.delete_expired_policies.assert_called_once_with(
        current_time=datetime(year=2012, month=1, day=14, hour=12, minute=0, second=1),
    )


@freeze_time("2012-01-14 12:00:01")
@patch.dict(os.environ, {"SNS_TOPIC_ARN": "SnsTopicArn"})
@patch("aws_grant_user_access.src.process_event.SNSMessagePublisher")
def test_publish_sns_message_with_a_sns_topic_arn_set(_mock_sns_message_publisher: Mock) -> None:
    sns_message = SNSMessage(
        account="123456789012",
        region="eu-west-2",
        role_arn="arn:aws:iam::123456789012:role/RoleEngineerUserAccess",
        usernames=["test-user-1", "test-user-2", "test-user-3"],
        hours=1,
        time_window=GrantTimeWindow(hours=1),
    )

    publisher = _mock_sns_message_publisher.return_value
    publisher.publish_sns_message.return_value = Mock()
    publish_sns_message(message=sns_message)
    print(publisher.mock_calls)

    publisher.publish_sns_message.assert_called_once_with(
        sns_topic_arn="SnsTopicArn", message=json.dumps(TEST_SNS_MESSAGE)
    )


@freeze_time("2012-01-14 12:00:01")
@patch("aws_grant_user_access.src.process_event.SNSMessagePublisher")
def test_publish_sns_message_with_no_sns_topic_arn_set(_mock_sns_message_publisher: Mock) -> None:
    sns_message = SNSMessage(
        account="123456789012",
        region="eu-west-2",
        role_arn="arn:aws:iam::123456789012:role/RoleEngineerUserAccess",
        usernames=["test-user-1", "test-user-2"],
        hours=1,
        time_window=GrantTimeWindow(hours=1),
    )

    publisher = _mock_sns_message_publisher.return_value
    publisher.publish_sns_message.return_value = Mock()
    publish_sns_message(message=sns_message)

    assert publisher.publish_sns_message.call_count == 0


@patch("aws_grant_user_access.src.process_event.SNSMessagePublisher")
def test_invalid_time_window(_mock_policy_creator: Mock) -> None:
    context = Mock()

    assert (
        process_event(dict(role_arn=TEST_ROLE_ARN, usernames=TEST_USERS, approval_in_hours=8761), context)
        == "Invalid time period specified: 8761 hours. Valid input is 1-8760 hours (1 year)."
    )


@mock_iam
@patch("aws_grant_user_access.src.process_event.PolicyCreator")
def test_deny_grant_to_platform_owner(_mock_policy_creator: Mock) -> None:
    moto_client = boto3.client("iam")
    context = Mock()

    policy_creator = _mock_policy_creator.return_value
    policy_creator.grant_access.return_value = Mock()

    _mock_users_and_group(["test-platform-owner-1"], "test_platform_owner")

    moto_client.list_groups_for_user(UserName="test-platform-owner-1")["Groups"]
    assert (
        process_event(dict(role_arn=TEST_ROLE_ARN, usernames=["test-platform-owner-1"], approval_in_hours=12), context)
        == "test-platform-owner-1 appears to not be an engineer so is invalid for this request."
    )
    assert 0 == policy_creator.grant_access.call_count


@mock_iam
@patch("aws_grant_user_access.src.process_event.PolicyCreator")
def test_deny_grant_to_non_engineer_role(_mock_policy_creator: Mock) -> None:
    moto_client = boto3.client("iam")
    context = Mock()

    policy_creator = _mock_policy_creator.return_value
    policy_creator.grant_access.return_value = Mock()

    _mock_users_and_group(["test-platform-engineer-1"], "test_platform_engineer")

    moto_client.list_groups_for_user(UserName="test-platform-engineer-1")["Groups"]
    assert (
        process_event(
            dict(role_arn=TEST_PO_ROLE_ARN, usernames=["test-platform-engineer-1"], approval_in_hours=12), context
        )
        == f"arn:aws:iam::123456789012:role/RolePlatformOwnerUserAccess is not a permitted engineering role. Valid options are {PERMITTED_ROLES}"
    )
    assert 0 == policy_creator.grant_access.call_count
