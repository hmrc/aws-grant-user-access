from jsonschema.validators import validate

from aws_grant_user_access.src.policy_creator import PolicyCreator

SCHEMA = {
     "type" : "object",
     "properties" : {
         "username" :{"type" : "string", "description": "The AWS IAM username that will be granted access"},
         "approval_in_hours" :{
             "type" : "number",
             "description": "a number of hours to approve access before it expires"
         },
     },
    "required": ["username", "approval_in_hours"]
 }


def handle(event, context):
    iam_client = PolicyCreator()
    process_event(event, iam_client)

def process_event(event, iam_client):
    validate(instance=event, schema=SCHEMA)
    iam_client.grant_access(username='testuser', start_time='someimte now', endtime="sometime 12 hours later")
