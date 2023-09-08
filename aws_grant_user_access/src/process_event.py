from jsonschema.validators import validate
from typing import Any, Dict

from aws_grant_user_access.src.grant_time_window import GrantTimeWindow

SCHEMA = {
    "type": "object",
    "properties": {
        "username": {"type": "array", "description": "The AWS IAM username(s) that will be granted access"},
        "role_arn": {"type": "string", "description": "The role the user will be allowed to access"},
        "approval_in_hours": {"type": "number", "description": "a number of hours to approve access before it expires"},
    },
    "required": ["username", "role_arn", "approval_in_hours"],
}


def process_event(event: Dict, policy_creator) -> None:
    validate(instance=event, schema=SCHEMA)
    time_window = GrantTimeWindow(hours=event["approval_in_hours"])

    for user in event["username"]:
        policy_creator.grant_access(
            role_arn=event["role_arn"],
            username=user,
            start_time=time_window.start_time,
            end_time=time_window.end_time,
        )
