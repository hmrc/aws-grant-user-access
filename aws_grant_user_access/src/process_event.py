import json
import os
from typing import Any, Dict
from jsonschema.validators import validate
from aws_grant_user_access.src.config.config import Config
from aws_grant_user_access.src.data.exceptions import MissingConfigException

from aws_grant_user_access.src.grant_time_window import GrantTimeWindow
from aws_grant_user_access.src.notifier import SNSMessage, SNSMessagePublisher
from aws_grant_user_access.src.policy_manager import PolicyCreator

# from aws_grant_user_access.src.clients.aws_iam_client import AwsIamClient
# from aws_grant_user_access.src.data.exceptions import AwsClientException

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


def process_event(event: Dict[str, Any], context: Any) -> str:
    logger = Config.configure_logging()
    validate(instance=event, schema=SCHEMA)
    input_validation = validate_request(event)
    if input_validation != "Input validated":
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


def validate_request(event: Dict[str, Any]) -> str:
    logger = Config.configure_logging()
    iam_client = config.get_iam_client()
    user_names = event["usernames"]
    role_arn = event["role_arn"]
    # breakpoint()
    #check time range is valid
    if not 1 <= event["approval_in_hours"] <= 8760:
        retmsg = f"Invalid time period specified: {event['approval_in_hours']} hours. Valid input is 1-8760 hours"
        logger.info(retmsg)
        return retmsg
    #check role is an engineer role
    if 'Engineer' not in role_arn:
        #breakpoint()
        retmsg = f"{role_arn} is not an engineering role. Only engineering roles are valid."
        logger.info(retmsg)
        # breakpoint()
        return retmsg
    #check user is an engineer
    for name in user_names:
        # breakpoint()
        #groups = iam_client.list_groups_for_user(name)
        user_groups = [grp['GroupName'] for grp in iam_client.list_groups_for_user(user_name=name)['Groups']]
        if 'platform_owner' in user_groups or 'engineer' not in user_groups:
            retmsg = f"{name} appears to not be an engineer so is invalid for this request."
            logger.info(retmsg)
            # breakpoint()
            return retmsg
    # breakpoint()
    return "Input validated"
