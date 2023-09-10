import json
from datetime import datetime, UTC
from typing import Any, Dict, List
from aws_grant_user_access.src.data.data import AWS_IAM_TIME_FORMAT

from aws_grant_user_access.src.clients.aws_iam_client import AwsIamClient


PRODUCT_TAG_VALUE = "grant-user-access"
PRODUCT_TAG_KEY = "Product"

EXPIRES_AT_TAG_KEY = "Expires_At"

GRANT_USER_ACCESS_PATH = "/Lambda/GrantUserAccess/"

class PolicyCreator:
    def __init__(self, iam_client: AwsIamClient) -> None:
        self.iam_client = iam_client

    def grant_access(self, role_arn: str, username: str, start_time: datetime, end_time: datetime) -> None:
        policy_arn = self.create_iam_policy(
            name=f"{username}_{datetime.timestamp(start_time)}",
            policy_document=PolicyCreator.generate_policy_document(
                role_arn=role_arn, start_time=start_time, end_time=end_time
            ),
            end_time=end_time,
        )

        self.attach_policy_to_user(
            username=username,
            policy_arn=policy_arn,
        )

    def create_iam_policy(self, policy_document: Dict[str, Any], name: str, end_time: datetime) -> str:
        return self.iam_client.create_policy(
            policy_name=name,
            path=GRANT_USER_ACCESS_PATH,
            policy_document=json.dumps(policy_document),
            description="An IAM policy to grant-user-access to assume a role",
            tags=[
                {"Key": PRODUCT_TAG_KEY, "Value": PRODUCT_TAG_VALUE},
                {"Key": EXPIRES_AT_TAG_KEY, "Value": end_time.strftime(AWS_IAM_TIME_FORMAT)},
            ],
        )

    @staticmethod
    def generate_policy_document(role_arn: str, start_time: datetime, end_time: datetime) -> Dict[str, Any]:
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

    def attach_policy_to_user(self, username: str, policy_arn: str) -> Any:
        return self.iam_client.attach_user_policy(username=username, policy_arn=policy_arn)

    def find_expired_policies(self, current_time: datetime) -> List[str]:
        all_policies = self.iam_client.list_policies(path_prefix=GRANT_USER_ACCESS_PATH)

        expired_policies = []
        for policy in all_policies["Policies"]:
            if self.is_policy_expired(policy, current_time):
                expired_policies.append(policy["Arn"])

        return expired_policies

    def is_policy_expired(self, policy: Dict[str, Any], current_time: datetime) -> bool:
        tag_dict = self.to_dict(policy["Tags"])

        return (
            {EXPIRES_AT_TAG_KEY, PRODUCT_TAG_KEY}.issubset(set(tag_dict.keys()))
            and tag_dict[PRODUCT_TAG_KEY] == PRODUCT_TAG_VALUE
            and datetime.strptime(tag_dict[EXPIRES_AT_TAG_KEY], AWS_IAM_TIME_FORMAT) < current_time
        )

    def to_dict(self, tag_array: List[Dict[str, str]]) -> Dict[str, str]:
        tag_dict = {}
        for tag in tag_array:
            tag_dict[tag["Key"]] = tag["Value"]
        return tag_dict

    def get_policy_name(self, policy_arn: str) -> Any:
        return self.iam_client.get_policy(policy_arn=policy_arn)["Policy"]["PolicyName"]

    def detach_expired_policies_from_users(self, current_time: datetime) -> None:
        for policy_arn in self.find_expired_policies(current_time):
            policy_name = self.get_policy_name(policy_arn=policy_arn)
            attached_user = policy_name.partition("_")[0]
            self.iam_client.detach_user_policy(username=attached_user, policy_arn=policy_arn)

    def delete_expired_policies(self, current_time: datetime) -> None:
        self.detach_expired_policies_from_users(current_time)
        for policy_arn in self.find_expired_policies(current_time):
            self.iam_client.delete_policy(policy_arn=policy_arn)