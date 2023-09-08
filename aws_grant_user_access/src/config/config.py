from os import environ
from typing import Callable, Dict, Set, List
from aws_grant_user_access.src.clients.aws_client_factory import AwsClientFactory
from aws_grant_user_access.src.clients.aws_iam_client import AwsIamClient
from aws_grant_user_access.src.clients.aws_sns_client import AwsSnsClient
from aws_grant_user_access.src.data.exceptions import InvalidConfigException, MissingConfigException


class Config:
    def get_sns_topic_arn(self) -> str:
        return self._get_env("SNS_TOPIC_ARN")

    @staticmethod
    def get_log_level() -> str:
        log_level_cfg = environ.get("LOG_LEVEL", "WARNING")
        log_level = log_level_cfg.upper()
        if log_level not in ["CRITICAL", "FATAL", "ERROR", "WARNING", "WARN", "INFO", "DEBUG"]:
            raise InvalidConfigException(f"invalid LOG_LEVEL: {log_level_cfg}")

        return log_level

    def get_iam_client(self) -> AwsIamClient:
        return AwsClientFactory().get_iam_client()

    def get_sns_client(self) -> AwsSnsClient:
        return AwsClientFactory().get_sns_client()

    @staticmethod
    def _get_env(key: str) -> str:
        try:
            return environ[key]
        except KeyError:
            raise MissingConfigException(f"environment variable {key}") from None
