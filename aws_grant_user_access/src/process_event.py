import json

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

PERMITTED_ROLES = [
    "engineer",
    "RoleTerraformApplier",
    "RoleTerraformProvisioner",
    "RoleBitwardenEmergencyAccess",
    "RoleStacksetAdministrator",
    "RoleSSMAccess",
]

ONE_WEEK = 168

config = Config()


def process_event(event: Dict[str, Any], context: Any) -> Any:
    logger = Config.configure_logging()
    validate(instance=event, schema=SCHEMA)
    input_validation = validate_request(event)
    if input_validation != "Valid Request":
        logger.info(input_validation)
        return input_validation
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
    retmsg = f"Access to {event['role_arn']} granted to {event['usernames']} for {event['approval_in_hours']} hours"
    logger.info(retmsg)

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
    return retmsg


def publish_sns_message(message: SNSMessage) -> None:
    try:
        sns_topic_arn = config.get_sns_topic_arn()
    except MissingConfigException as error:
        sns_topic_arn = None

    if sns_topic_arn:
        SNSMessagePublisher(config.get_sns_client()).publish_sns_message(
            sns_topic_arn=sns_topic_arn, message=json.dumps(message.to_dict())
        )


def _validate_role(role_arn: str) -> bool:
    for role in PERMITTED_ROLES:
        if role.lower() in role_arn.lower():
            return True
    return False


def _validate_user(user_name: str) -> bool:
    iam_client = config.get_iam_client()
    user_groups = [grp["GroupName"] for grp in iam_client.list_groups_for_user(user_name=user_name)["Groups"]]
    if [e for e in user_groups if "engineer" not in e.lower()] or [
        o for o in user_groups if "platform_owner" in o.lower()
    ]:
        return False
    return True


def validate_request(event: Dict[str, Any]) -> Any:
    logger = Config.configure_logging()
    user_names = event["usernames"]
    role_arn = event["role_arn"]
    if not 1 <= event["approval_in_hours"] <= ONE_WEEK:
        retmsg = (
            f"Invalid time period specified: {event['approval_in_hours']} hours. Valid input is 1-168 hours (1 week)."
        )
        logger.info(retmsg)
        return retmsg
    if not _validate_role(role_arn):
        retmsg = f"{role_arn} is not a permitted engineering role. Valid options are {PERMITTED_ROLES}"
        logger.info(retmsg)
        return retmsg
    for user_name in user_names:
        if not _validate_user(user_name):
            retmsg = f"{user_name} appears to not be an engineer so is invalid for this request."
            logger.info(retmsg)
            return retmsg
    return "Valid Request"
