import json
from typing import Any, Dict, List

from datetime import datetime, UTC

PRODUCT_TAG_VALUE = "grant-user-access"
PRODUCT_TAG_KEY = "Product"

EXPIRES_AT_TAG_KEY = "Expires_At"

GRANT_USER_ACCESS_PATH = "/Lambda/GrantUserAccess/"

AWS_IAM_TIME_FORMAT = "%Y-%m-%dT%H:%M:%SZ"


class PolicyCreator:
    def __init__(self, iam_client) -> None:
        self.iam_client = iam_client

    def grant_access(self, role_arn: str, username: str, start_time: str, end_time: str) -> None:
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

    def create_iam_policy(self, policy_document: Dict, name: str, end_time: str) -> str:
        response = self.iam_client.create_policy(
            PolicyName=name,
            Path=GRANT_USER_ACCESS_PATH,
            PolicyDocument=json.dumps(policy_document),
            Description="An IAM policy to grant-user-access to assume a role",
            Tags=[
                {"Key": PRODUCT_TAG_KEY, "Value": PRODUCT_TAG_VALUE},
                {"Key": EXPIRES_AT_TAG_KEY, "Value": end_time.strftime(AWS_IAM_TIME_FORMAT)},
            ],
        )
        return response["Policy"].get("Arn")

    @staticmethod
    def generate_policy_document(role_arn: str, start_time: str, end_time: str) -> Dict[str, Any]:
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

    def attach_policy_to_user(self, policy_document_arn: str, username: str) -> None:
        self.iam_client.attach_user_policy(UserName=username, PolicyArn=policy_document_arn)

    def find_expired_policies(self, current_time: str) -> List:
        all_policies = self.iam_client.list_policies(PathPrefix=GRANT_USER_ACCESS_PATH)

        expired_policies = []
        for policy in all_policies["Policies"]:
            if self.is_policy_expired(policy, current_time):
                expired_policies.append(policy["Arn"])

        return expired_policies

    def is_policy_expired(self, policy: Dict, current_time: str) -> Any:
        tag_dict = self.to_dict(policy["Tags"])

        return (
            {EXPIRES_AT_TAG_KEY, PRODUCT_TAG_KEY}.issubset(set(tag_dict.keys()))
            and tag_dict[PRODUCT_TAG_KEY] == PRODUCT_TAG_VALUE
            and datetime.strptime(tag_dict[EXPIRES_AT_TAG_KEY], AWS_IAM_TIME_FORMAT) < current_time
        )

    def to_dict(self, tag_array: List) -> Dict[str, Any]:
        tag_dict = {}
        for tag in tag_array:
            tag_dict[tag["Key"]] = tag["Value"]
        return tag_dict

    def get_policy_name(self, policy_arn, str) -> str:
        policy_details = self.iam_client.get_policy(PolicyArn=policy_arn)
        return policy_details["Policy"]["PolicyName"]

    def detach_expired_policies_from_users(self, current_time: str) -> None:
        for policy in self.find_expired_policies(current_time):
            policy_name = self.get_policy_name(policy_arn=policy)
            attached_user = policy_name.partition("_")[0]
            self.iam_client.detach_user_policy(UserName=attached_user, PolicyArn=policy)

    def delete_expired_policies(self, current_time: str) -> None:
        self.detach_expired_policies_from_users(current_time)
        for policy in self.find_expired_policies(current_time):
            self.iam_client.delete_policy(PolicyArn=policy)
