from unittest.mock import Mock, patch

import pytest
from jsonschema.exceptions import ValidationError

from aws_grant_user_access.src.main import handle, process_event, PolicyCreator

TEST_ROLE_ARN = "arn:aws:iam::123456789012:role/RoleUserAccess"

@patch("aws_grant_user_access.src.main.PolicyCreator")
def test_handler_takes_a_granted_event(_mock_policy):
    handle(dict(role_arn=TEST_ROLE_ARN, username="testuser", approval_in_hours=12), dict(context=1))

def test_handler_rejects_invalid_events():
    with pytest.raises(ValidationError):
        handle(dict(username="testuser"), dict(context=1))

def test_process_event_creates_iam_policy():
    client = Mock(spec=PolicyCreator)
    test_user = "test-user"
    process_event(dict(role_arn=TEST_ROLE_ARN, username=test_user, approval_in_hours=12), iam_client=client)

    client.grant_access.assert_called_with(role_arn=TEST_ROLE_ARN, username=test_user, start_time="someimte now", end_time="sometime 12 hours later")
