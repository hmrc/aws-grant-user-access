import json
import os
from typing import Any, Dict
from jsonschema.validators import validate
from aws_grant_user_access.src.config.config import Config
from aws_grant_user_access.src.data.exceptions import MissingConfigException

from aws_grant_user_access.src.grant_time_window import GrantTimeWindow
from aws_grant_user_access.src.notifier import SNSMessage, SNSMessagePublisher
from aws_grant_user_access.src.policy_manager import PolicyCreator

SCHEMA = {
    "type": "object",
    "properties": {
        "usernames": {"type": "array", "description": "The AWS IAM username(s) that will be granted access"},
        "role_arn": {"type": "string", "description": "The role the user will be allowed to access"},
        "approval_in_hours": {"type": "number", "description": "a number of hours to approve access before it expires"},
    },
    "required": ["usernames", "role_arn", "approval_in_hours"],
}

config = Config()


def process_event(event: Dict[str, Any]) -> None:
    logger = Config.configure_logging()

    validate(instance=event, schema=SCHEMA)
    time_window = GrantTimeWindow(hours=event["approval_in_hours"])
    policy_creator = PolicyCreator(config.get_iam_client())
    policy_creator.detach_expired_policies_from_users(current_time=time_window.start_time)
    policy_creator.delete_expired_policies(current_time=time_window.start_time)

    for user in event["usernames"]:
        policy_creator.grant_access(
            role_arn=event["role_arn"],
            username=user,
            start_time=time_window.start_time,
            end_time=time_window.end_time,
        )

    logger.info(f"Access to {event['role_arn']} granted to {event['usernames']} for {event['approval_in_hours']} hours")

    publish_sns_message(event, time_window)


def publish_sns_message(event: Dict[str, Any], time_window: GrantTimeWindow) -> None:
    try:
        sns_topic_arn = config.get_sns_topic_arn()
    except MissingConfigException as error:
        sns_topic_arn = None

    if sns_topic_arn:
        message = SNSMessage.generate(
            grantor="", usernames=event["usernames"], role_arn=event["role_arn"], time_window=time_window
        )
        SNSMessagePublisher(config.get_sns_client()).publish_sns_message(
            sns_topic_arn=sns_topic_arn, message=json.dumps(message)
        )
