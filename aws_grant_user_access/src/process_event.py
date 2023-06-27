from jsonschema.validators import validate

from aws_grant_user_access.src.grant_time_window import GrantTimeWindow

SCHEMA = {
    "type": "object",
    "properties": {
        "username": {"type": "string", "description": "The AWS IAM username that will be granted access"},
        "role_arn": {"type": "string", "description": "The role the user will be allowed to access"},
        "approval_in_hours": {"type": "number", "description": "a number of hours to approve access before it expires"},
    },
    "required": ["username", "role_arn", "approval_in_hours"],
}


def process_event(event, policy_creator):
    validate(instance=event, schema=SCHEMA)
    time_window = GrantTimeWindow(hours=event["approval_in_hours"])
    policy_creator.grant_access(
        role_arn=event["role_arn"],
        username=event["username"],
        start_time=time_window.start_time,
        end_time=time_window.end_time,
    )
