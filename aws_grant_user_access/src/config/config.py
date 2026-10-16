import logging
from os import environ
from typing import List
from aws_grant_user_access.src.clients.aws_client_factory import AwsClientFactory
from aws_grant_user_access.src.clients.aws_iam_client import AwsIamClient
from aws_grant_user_access.src.clients.aws_secrets_manager import AwsSecretsManagerClient
from aws_grant_user_access.src.clients.slack_client import SlackClient
from aws_grant_user_access.src.data.exceptions import InvalidConfigException, MissingConfigException

SLACK_NOTIFICATION_SERVICE_ENDPOINT = "https://slack-notifications.tax.service.gov.uk/api/v2/notification"


class Config:

    def get_slack_channels(self) -> List[str]:
        return self._get_env("SLACK_CHANNELS").split(",")

    def get_slack_api_secret_arn(self) -> str:
        return self._get_env("SLACK_API_SECRET_ARN")

    @staticmethod
    def is_dry_run() -> bool:
        dry_run = environ.get("DRY_RUN", "false").lower()
        if dry_run not in ["true", "false"]:
            raise InvalidConfigException(f"invalid DRY_RUN: {dry_run}")
        return dry_run == "true"

    def get_slack_client(self) -> SlackClient:
        api_secret_arn = self.get_slack_api_secret_arn()
        api_key = self.get_secrets_manager_client().get_secret_value(api_secret_arn)
        return SlackClient(webhook_url=SLACK_NOTIFICATION_SERVICE_ENDPOINT, api_key=api_key)

    @staticmethod
    def get_log_level() -> str:
        log_level_cfg = environ.get("LOG_LEVEL", "WARNING")
        log_level = log_level_cfg.upper()
        if log_level not in ["CRITICAL", "FATAL", "ERROR", "WARNING", "WARN", "INFO", "DEBUG"]:
            raise InvalidConfigException(f"invalid LOG_LEVEL: {log_level_cfg}")

        return log_level

    def get_iam_client(self) -> AwsIamClient:
        return AwsClientFactory().get_iam_client()

    def get_secrets_manager_client(self) -> AwsSecretsManagerClient:
        return AwsClientFactory().get_secrets_manager_client()

    @staticmethod
    def _get_env(key: str) -> str:
        try:
            return environ[key]
        except KeyError:
            raise MissingConfigException(f"environment variable {key}") from None

    @staticmethod
    def configure_logging() -> logging.Logger:
        logger = logging.getLogger()
        logger.setLevel(Config.get_log_level())
        logging.getLogger("botocore").setLevel(logging.ERROR)
        logging.getLogger("boto3").setLevel(logging.ERROR)
        logging.getLogger("requests").setLevel(logging.ERROR)
        logging.getLogger("urllib3").setLevel(logging.ERROR)
        return logger
