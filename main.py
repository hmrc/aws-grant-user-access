import boto3

from aws_grant_user_access.src.policy_manager import PolicyCreator
from aws_grant_user_access.src.process_event import process_event


def handle(event, context):
    iam_client = boto3.client("iam")
    process_event(event, PolicyCreator(iam_client))
