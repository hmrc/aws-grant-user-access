from aws_grant_user_access.src.process_event import process_event


def handle(event, context):
    process_event(event)
