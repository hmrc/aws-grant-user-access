import json
from datetime import datetime, UTC

EXPIRES_AT_TAG = "Expires_At"

GRANT_USER_ACCESS_PATH = "/Lambda/GrantUserAccess/"

AWS_IAM_TIME_FORMAT = "%Y-%m-%dT%H:%M:%SZ"


class PolicyCreator:
    def __init__(self, iam_client):
        self.iam_client = iam_client

    def grant_access(self, role_arn, username, start_time, end_time):
        policy_arn = self.create_iam_policy(
            name=f"{username}_{datetime.timestamp(start_time)}",
            policy_document=PolicyCreator.generate_policy_document(
                role_arn=role_arn, start_time=start_time, end_time=end_time
            ),
            end_time=end_time,
        )

        self.attach_policy_to_user(
            username=username,
            policy_document_arn=policy_arn,
        )

    def create_iam_policy(self, policy_document, name, end_time):
        response = self.iam_client.create_policy(
            PolicyName=name,
            Path=GRANT_USER_ACCESS_PATH,
            PolicyDocument=json.dumps(policy_document),
            Description="An IAM policy to grant-user-access to assume a role",
            Tags=[
                {"Key": "Product", "Value": "grant-user-access"},
                {"Key": EXPIRES_AT_TAG, "Value": end_time.strftime(AWS_IAM_TIME_FORMAT)},
            ],
        )
        return response["Policy"].get("Arn")

    @staticmethod
    def generate_policy_document(role_arn, start_time, end_time):
        policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": "sts:AssumeRole",
                    "Resource": role_arn,
                    "Condition": {
                        "DateGreaterThan": {"aws:CurrentTime": start_time.strftime(AWS_IAM_TIME_FORMAT)},
                        "DateLessThan": {"aws:CurrentTime": end_time.strftime(AWS_IAM_TIME_FORMAT)},
                    },
                }
            ],
        }

        return policy

    def attach_policy_to_user(self, policy_document_arn, username):
        self.iam_client.attach_user_policy(UserName=username, PolicyArn=policy_document_arn)

    def find_expired_policies(self, current_time):
        all_policies = self.iam_client.list_policies(PathPrefix=GRANT_USER_ACCESS_PATH)

        expired_policies = []
        for policy in all_policies["Policies"]:
            for tag in policy["Tags"]:
                if tag["Key"] == EXPIRES_AT_TAG:
                    if datetime.strptime(tag["Value"], AWS_IAM_TIME_FORMAT) < current_time:
                        expired_policies.append(policy["Arn"])
                        break

        return expired_policies
