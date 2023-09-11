from datetime import datetime, timedelta
from unittest.mock import Mock, patch

import pytest

from freezegun import freeze_time
from jsonschema.exceptions import ValidationError

from aws_grant_user_access.src.policy_manager import PolicyCreator
from aws_grant_user_access.src.process_event import process_event
from main import handle

TEST_ROLE_ARN = "arn:aws:iam::123456789012:role/RoleUserAccess"
TEST_USERS = ["test-user-1", "test-user-2", "test-user-3"]


@patch("main.PolicyCreator")
def test_handler_takes_a_granted_event(_mock_policy) -> None:
    handle(dict(role_arn=TEST_ROLE_ARN, username=TEST_USERS, approval_in_hours=12), dict(context=1))


def test_handler_rejects_invalid_events() -> None:
    with pytest.raises(ValidationError):
        handle(dict(username="testuser"), dict(context=1))


@freeze_time("2012-01-14 12:00:01")
def test_process_event_creates_iam_policy() -> None:
    client = Mock(spec=PolicyCreator)
    process_event(dict(role_arn=TEST_ROLE_ARN, username=TEST_USERS, approval_in_hours=12), policy_creator=client)

    client.grant_access.assert_any_call(
        role_arn=TEST_ROLE_ARN,
        username=TEST_USERS[1],
        start_time=datetime(year=2012, month=1, day=14, hour=12, minute=0, second=1),
        end_time=datetime(year=2012, month=1, day=15, hour=0, minute=0, second=1),
    )

    client.grant_access.assert_any_call(
        role_arn=TEST_ROLE_ARN,
        username=TEST_USERS[0],
        start_time=datetime(year=2012, month=1, day=14, hour=12, minute=0, second=1),
        end_time=datetime(year=2012, month=1, day=15, hour=0, minute=0, second=1),
    )

    assert 3 == client.grant_access.call_count


@freeze_time("2012-01-14 12:00:01")
def test_process_event_deletes_expired_policies() -> None:
    client = Mock(spec=PolicyCreator)
    process_event(dict(role_arn=TEST_ROLE_ARN, username=TEST_USERS, approval_in_hours=12), policy_creator=client)

    client.delete_expired_policies.assert_called_once_with(
        current_time=datetime(year=2012, month=1, day=14, hour=12, minute=0, second=1),
    )
