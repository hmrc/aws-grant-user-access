from unittest.mock import Mock

import pytest
from jsonschema.exceptions import ValidationError

from aws_grant_user_access.src.main import handle, process_event, PolicyCreator


def test_handler_takes_a_granted_event():
    handle(dict(username="testuser", approval_in_hours=12), dict(context=1))

def test_handler_rejects_invalid_events():
    with pytest.raises(ValidationError):
        handle(dict(username="testuser"), dict(context=1))

def test_process_event_creates_iam_policy():
    client = Mock(spec=PolicyCreator)
    test_user = "testuser"
    process_event(dict(username=test_user, approval_in_hours=12), iam_client=client)

    client.grant_access.assert_called_with(username=test_user, start_time="someimte now", endtime="sometime 12 hours later")


