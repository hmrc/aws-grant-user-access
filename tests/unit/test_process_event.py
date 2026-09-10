from datetime import datetime
import json
import logging
import os
import boto3
from pytest import LogCaptureFixture
from moto import mock_aws
from unittest.mock import Mock, patch
from aws_grant_user_access.src.grant_time_window import GrantTimeWindow
from aws_grant_user_access.src.data.exceptions import AwsClientException, SlackNotificationException
from aws_grant_user_access.src.notifier import SNSMessage, SlackMessage
from aws_grant_user_access.src.process_event import (
    filter_non_platform_engineers,
    is_a_platform_engineer,
    process_event,
    publish_slack_message,
    publish_sns_message,
)
from typing import Any, Dict, List
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


def _mock_users_and_group(usernames: Any, groupname: Any) -> None:
    moto_client = boto3.client("iam")

    moto_client.create_group(Path="/", GroupName=groupname)

    for username in usernames:
        moto_client.create_user(UserName=username)
        moto_client.add_user_to_group(GroupName=groupname, UserName=username)


@freeze_time("2012-01-14 12:00:01")
@patch("aws_grant_user_access.src.process_event.PolicyCreator")
@mock_aws
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
@patch("aws_grant_user_access.src.process_event.publish_slack_message")
@patch("aws_grant_user_access.src.process_event.PolicyCreator")
@mock_aws
def test_process_event_continues_granting_access_when_one_user_fails(
    _mock_policy_creator: Mock, _mock_publish_slack_message: Mock, caplog: LogCaptureFixture
) -> None:
    caplog.set_level(logging.ERROR)
    _mock_users_and_group(TEST_USERS, "test_platform_engineer")

    context = Mock()
    context.invoked_function_arn = "arn:aws:lambda:eu-west-2:123456789012:function:grant-user-access"

    policy_creator = _mock_policy_creator.return_value
    policy_creator.grant_access.side_effect = [None, AwsClientException("boom"), None]
    process_event(dict(role_arn=TEST_ROLE_ARN, usernames=TEST_USERS, approval_in_hours=12), context)

    assert 3 == policy_creator.grant_access.call_count
    assert f"failed to grant access to {TEST_ROLE_ARN} for {TEST_USERS[1]}: boom" in caplog.text

    _mock_publish_slack_message.assert_called_once()
    slack_message = _mock_publish_slack_message.call_args.kwargs["message"]
    assert slack_message.usernames == [TEST_USERS[0], TEST_USERS[2]]


@freeze_time("2012-01-14 12:00:01")
@patch("aws_grant_user_access.src.process_event.publish_slack_message")
@patch("aws_grant_user_access.src.process_event.PolicyCreator")
@mock_aws
def test_process_event_does_not_notify_when_all_users_fail(
    _mock_policy_creator: Mock, _mock_publish_slack_message: Mock
) -> None:
    _mock_users_and_group(TEST_USERS, "test_platform_engineer")

    context = Mock()
    context.invoked_function_arn = "arn:aws:lambda:eu-west-2:123456789012:function:grant-user-access"

    policy_creator = _mock_policy_creator.return_value
    policy_creator.grant_access.side_effect = AwsClientException("boom")
    process_event(dict(role_arn=TEST_ROLE_ARN, usernames=TEST_USERS, approval_in_hours=12), context)

    assert 3 == policy_creator.grant_access.call_count
    _mock_publish_slack_message.assert_not_called()


@freeze_time("2012-01-14 12:00:01")
@patch("aws_grant_user_access.src.process_event.PolicyCreator")
@mock_aws
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


@freeze_time("2012-01-14 12:00:01")
@patch("aws_grant_user_access.src.process_event.SlackMessagePublisher")
def test_publish_slack_message_with_config_set(_mock_slack_message_publisher: Mock, monkeypatch: Any) -> None:
    monkeypatch.setenv("SLACK_CHANNELS", "#a-channel")

    slack_message = SlackMessage(
        role_arn="arn:aws:iam::123456789012:role/RoleEngineerUserAccess",
        usernames=["test-user-1", "test-user-2"],
        hours=1,
        time_window=GrantTimeWindow(hours=1),
    )

    with patch("aws_grant_user_access.src.process_event.config.get_slack_client") as _mock_get_slack_client:
        publisher = _mock_slack_message_publisher.return_value
        publisher.publish_slack_message.return_value = Mock()
        publish_slack_message(message=slack_message)

        publisher.publish_slack_message.assert_called_once_with(channels=["#a-channel"], message=slack_message)
        _mock_get_slack_client.assert_called_once()


@freeze_time("2012-01-14 12:00:01")
@patch("aws_grant_user_access.src.process_event.SlackMessagePublisher")
def test_publish_slack_message_does_not_raise_on_notification_failure(
    _mock_slack_message_publisher: Mock, monkeypatch: Any, caplog: LogCaptureFixture
) -> None:
    caplog.set_level(logging.WARNING)
    monkeypatch.setenv("SLACK_CHANNELS", "#a-channel")

    slack_message = SlackMessage(
        role_arn="arn:aws:iam::123456789012:role/RoleEngineerUserAccess",
        usernames=["test-user-1", "test-user-2"],
        hours=1,
        time_window=GrantTimeWindow(hours=1),
    )

    with patch("aws_grant_user_access.src.process_event.config.get_slack_client"):
        publisher = _mock_slack_message_publisher.return_value
        publisher.publish_slack_message.side_effect = SlackNotificationException("boom")

        publish_slack_message(message=slack_message)

    assert "failed to publish slack message: boom" in caplog.text


@freeze_time("2012-01-14 12:00:01")
@patch("aws_grant_user_access.src.process_event.SlackMessagePublisher")
def test_publish_slack_message_with_no_config_set(_mock_slack_message_publisher: Mock, monkeypatch: Any) -> None:
    monkeypatch.delenv("SLACK_CHANNELS", raising=False)

    slack_message = SlackMessage(
        role_arn="arn:aws:iam::123456789012:role/RoleEngineerUserAccess",
        usernames=["test-user-1", "test-user-2"],
        hours=1,
        time_window=GrantTimeWindow(hours=1),
    )

    publish_slack_message(message=slack_message)

    assert _mock_slack_message_publisher.return_value.publish_slack_message.call_count == 0


@mock_aws
@patch.dict(os.environ, {"LOG_LEVEL": "INFO"})
@patch("aws_grant_user_access.src.process_event.PolicyCreator")
def test_deny_grant_to_platform_owner(_mock_policy_creator: Mock, caplog: LogCaptureFixture) -> None:
    caplog.set_level(logging.INFO)
    context = Mock()

    policy_creator = _mock_policy_creator.return_value
    policy_creator.grant_access.return_value = Mock()

    _mock_users_and_group(["test-platform-owner-1"], "test_platform_owner")

    process_event(dict(role_arn=TEST_ROLE_ARN, usernames=["test-platform-owner-1"], approval_in_hours=12), context)
    assert "The following users are not engineers: test-platform-owner-1. This request is invalid!" in caplog.text
    assert 0 == policy_creator.grant_access.call_count


def _mock_setup_users_and_groups(group_memberships: List[Dict[str, Any]]) -> None:
    moto_client = boto3.client("iam")
    all_groups = set([group for membership in group_memberships for group in membership["groups"]])

    for group_name in all_groups:
        moto_client.create_group(Path="/", GroupName=group_name)

    for membership in group_memberships:
        username = membership["username"]
        moto_client.create_user(UserName=username)
        for groupname in membership["groups"]:
            moto_client.add_user_to_group(GroupName=groupname, UserName=username)


@mock_aws
def test_is_a_platform_engineer() -> None:
    memberships = [
        {"username": "engineer.user01", "groups": ["platform_member", "team_engineer"]},
        {"username": "platform.owner01", "groups": ["platform_member", "platform_owner"]},
    ]
    _mock_setup_users_and_groups(memberships)

    assert is_a_platform_engineer("engineer.user01") is True
    assert is_a_platform_engineer("platform.owner01") is False


@patch("aws_grant_user_access.src.process_event.config")
def test_is_a_platform_engineer_returns_false_when_lookup_fails(_mock_config: Mock, caplog: LogCaptureFixture) -> None:
    caplog.set_level(logging.WARNING)
    _mock_config.get_iam_client.return_value.list_groups_for_user.side_effect = AwsClientException("boom")

    assert is_a_platform_engineer("engineer.user01") is False
    assert "failed to verify group membership for engineer.user01: boom" in caplog.text


@mock_aws
def test_filter_non_platform_engineers() -> None:
    memberships = [
        {"username": "engineer.user01", "groups": ["platform_member", "team_engineer"]},
        {"username": "platform.owner01", "groups": ["platform_member", "platform_owner"]},
    ]
    _mock_setup_users_and_groups(memberships)

    assert filter_non_platform_engineers(["engineer.user01", "platform.owner01"]) == {"platform.owner01"}
