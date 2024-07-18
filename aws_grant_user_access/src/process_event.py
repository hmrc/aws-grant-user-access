import json

from typing import Any, Dict, List, Set
from jsonschema.validators import validate
from aws_grant_user_access.src.config.config import Config
from aws_grant_user_access.src.data.exceptions import MissingConfigException

from aws_grant_user_access.src.grant_time_window import GrantTimeWindow
from aws_grant_user_access.src.notifier import SNSMessage, SNSMessagePublisher
from aws_grant_user_access.src.policy_manager import PolicyCreator


PERMITTED_ROLES = [
    "engineer",
    "RoleTerraformApplier",
    "RoleTerraformProvisioner",
    "RoleBitwardenEmergencyAccess",
    "RoleStacksetAdministrator",
    "RoleSSMAccess",
    "RoleSensitiveShellAccess",
    "RoleCredentialsRotation",
]

ONE_WEEK = 168

SCHEMA = {
    "type": "object",
    "properties": {
        "usernames": {"type": "array", "description": "The AWS IAM username(s) that will be granted access"},
        "role_arn": {
            "type": "string",
            "description": "The role the user will be allowed to access",
            "pattern": f"(?i)({'|'.join(PERMITTED_ROLES)})",
        },
        "approval_in_hours": {
            "type": "number",
            "description": "a number of hours to approve access before it expires",
            "minimum": 0,
            "maximum": ONE_WEEK,
        },
    },
    "required": ["usernames", "role_arn", "approval_in_hours"],
}

config = Config()


def process_event(event: Dict[str, Any], context: Any) -> None:
    logger = Config.configure_logging()
    validate(instance=event, schema=SCHEMA)

    non_platform_engineers = filter_non_platform_engineers(event["usernames"])
    if non_platform_engineers:
        logger.info(
            f"The following users are not engineers: {', '.join(non_platform_engineers)}. This request is invalid!"
        )
        return

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

    region = context.invoked_function_arn.split(":")[3]
    account = context.invoked_function_arn.split(":")[4]

    publish_sns_message(
        message=SNSMessage(
            account=account,
            region=region,
            role_arn=event["role_arn"],
            usernames=event["usernames"],
            hours=int(event["approval_in_hours"]),
            time_window=time_window,
        )
    )


def publish_sns_message(message: SNSMessage) -> None:
    try:
        sns_topic_arn = config.get_sns_topic_arn()
    except MissingConfigException:
        sns_topic_arn = None

    if sns_topic_arn:
        SNSMessagePublisher(config.get_sns_client()).publish_sns_message(
            sns_topic_arn=sns_topic_arn, message=json.dumps(message.to_dict())
        )


def is_a_platform_engineer(username: str) -> bool:
    iam_client = config.get_iam_client()
    groups = [grp["GroupName"] for grp in iam_client.list_groups_for_user(user_name=username)["Groups"]]
    return (
        len([e for e in groups if "engineer" in e.lower()]) > 0
        and len([po for po in groups if "platform_owner" in po.lower()]) == 0
    )


def filter_non_platform_engineers(usernames: List[str]) -> Set[str]:
    platform_engineers = filter(is_a_platform_engineer, usernames)
    return set(usernames) - set(platform_engineers)
