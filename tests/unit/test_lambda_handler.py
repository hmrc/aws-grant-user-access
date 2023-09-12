from datetime import datetime, timedelta
from typing import Any
from unittest.mock import Mock, patch

import pytest

from freezegun import freeze_time
from jsonschema.exceptions import ValidationError

from aws_grant_user_access.src.policy_manager import PolicyCreator
from aws_grant_user_access.src.process_event import process_event
from main import handle

TEST_ROLE_ARN = "arn:aws:iam::123456789012:role/RoleUserAccess"
TEST_USERS = ["test-user-1", "test-user-2", "test-user-3"]


@patch("main.process_event")
def test_handler_takes_a_granted_event(_mock_policy: Mock) -> None:
    handle(dict(role_arn=TEST_ROLE_ARN, usernames=TEST_USERS, approval_in_hours=12), dict(context=1))


def test_handler_rejects_invalid_events() -> None:
    with pytest.raises(ValidationError):
        handle(dict(username="testuser"), dict(context=1))
