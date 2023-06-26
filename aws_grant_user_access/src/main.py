from jsonschema.validators import validate

from aws_grant_user_access.src.policy_creator import PolicyCreator

SCHEMA = {
     "type" : "object",
     "properties" : {
         "username" :{"type" : "string", "description": "The AWS IAM username that will be granted access"},
         "role_arn" :{"type" : "string", "description": "The role the user will be allowed to access"},
         "approval_in_hours" :{
             "type" : "number",
             "description": "a number of hours to approve access before it expires"
         },
     },
    "required": ["username", "role_arn", "approval_in_hours"]
 }


def handle(event, context):
    process_event(event, PolicyCreator())

def process_event(event, policy_creator):
    validate(instance=event, schema=SCHEMA)
    policy_creator.grant_access(role_arn=event['role_arn'], username=event['username'], hours=event['approval_in_hours'])
