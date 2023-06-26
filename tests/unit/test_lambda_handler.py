from datetime import datetime, timedelta
from unittest.mock import Mock, patch

import pytest
from jsonschema.exceptions import ValidationError

from aws_grant_user_access.src.main import handle, process_event, PolicyCreator

TEST_ROLE_ARN = "arn:aws:iam::123456789012:role/RoleUserAccess"
TEST_USER = "test-user"

@patch("aws_grant_user_access.src.main.PolicyCreator")
def test_handler_takes_a_granted_event(_mock_policy):
    handle(dict(role_arn=TEST_ROLE_ARN, username=TEST_USER, approval_in_hours=12), dict(context=1))

def test_handler_rejects_invalid_events():
    with pytest.raises(ValidationError):
        handle(dict(username="testuser"), dict(context=1))

def test_process_event_creates_iam_policy():
    client = Mock(spec=PolicyCreator)
    process_event(dict(role_arn=TEST_ROLE_ARN, username=TEST_USER, approval_in_hours=12), policy_creator=client)

    client.grant_access.assert_called_with(
        role_arn=TEST_ROLE_ARN,
        username=TEST_USER,
        hours=12,
    )
