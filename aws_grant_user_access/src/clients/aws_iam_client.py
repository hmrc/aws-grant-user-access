import json
from typing import Any, Dict, List
from aws_grant_user_access.src.clients import boto_try
from botocore.client import BaseClient


class AwsIamClient:
    def __init__(self, boto_iam: BaseClient) -> None:
        self._iam = boto_iam

    def create_policy(
        self, policy_name: str, path: str, policy_document: str, description: str, tags: List[Dict[str, str]]
    ) -> str:
        return boto_try(
            lambda: str(
                self._iam.create_policy(
                    PolicyName=policy_name,
                    Path=path,
                    PolicyDocument=policy_document,
                    Description=description,
                    Tags=tags,
                )["Policy"].get("Arn")
            ),
            f"failed to create policy {policy_name}",
        )

    def attach_user_policy(self, username: str, policy_arn: str) -> Any:
        return boto_try(
            lambda: self._iam.attach_user_policy(UserName=username, PolicyArn=policy_arn),
            f"failed to attach policy {policy_arn} to {username}",
        )

    def list_policies(self, path_prefix: str) -> Dict[str, Any]:
        return boto_try(
            lambda: self._iam.list_policies(PathPrefix=path_prefix),
            f"failed to list policies with {path_prefix} path prefix",
        )

    def get_policy(self, policy_arn: str) -> Dict[str, Any]:
        return boto_try(
            lambda: self._iam.get_policy(PolicyArn=policy_arn),
            f"failed to get {policy_arn} policy",
        )

    def detach_user_policy(self, username: str, policy_arn: str) -> Any:
        return boto_try(
            lambda: self._iam.detach_user_policy(UserName=username, PolicyArn=policy_arn),
            f"failed to detach {policy_arn} policy from {username}",
        )

    def delete_policy(self, policy_arn: str) -> Any:
        return boto_try(
            lambda: self._iam.delete_policy(PolicyArn=policy_arn),
            f"failed to delete {policy_arn} policy",
        )

    def list_attached_user_policies(self, username: str, path_prefix: str) -> List[Dict[str, str]]:
        return boto_try(
            lambda: self._iam.list_attached_user_policies(UserName=username, PathPrefix=path_prefix)[
                "AttachedPolicies"
            ],
            f"failed to list attached user policies for {username}",
        )

    def get_user(self, user_name: str) -> Dict[str, Any]:
        return boto_try(
            lambda: self._iam.get_user(UserName=user_name),
            f"failed to get {user_name} user details",
        )

    def get_role(self, role_name: str) -> Dict[str, Any]:
        return boto_try(
            lambda: self._iam.get_role(RoleName=role_name),
            f"failed to get {role_name} role details",
        )

    def list_groups_for_user(self, user_name: str) -> Dict[str, Any]:
        return boto_try(
            lambda: self._iam.list_groups_for_user(UserName=user_name),
            f"failed to get list of groups for {user_name}",
        )
