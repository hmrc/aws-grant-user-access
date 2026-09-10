import logging
from os import environ
from typing import List
from aws_grant_user_access.src.clients.aws_client_factory import AwsClientFactory
from aws_grant_user_access.src.clients.aws_iam_client import AwsIamClient
from aws_grant_user_access.src.clients.aws_sns_client import AwsSnsClient
from aws_grant_user_access.src.clients.aws_ssm_client import AwsSsmClient
from aws_grant_user_access.src.clients.slack_client import SlackClient
from aws_grant_user_access.src.data.exceptions import InvalidConfigException, MissingConfigException

SLACK_NOTIFICATION_SERVICE_ENDPOINT = "https://slack-notifications.tax.service.gov.uk/api/v2/notification"
SLACK_V2_API_KEY_PARAMETER_NAME = "/service_accounts/slack_v2_api_key"


class Config:
    def get_sns_topic_arn(self) -> str:
        return self._get_env("SNS_TOPIC_ARN")

    def get_slack_channels(self) -> List[str]:
        return self._get_env("SLACK_CHANNELS").split(",")

    def get_slack_client(self) -> SlackClient:
        api_key = self.get_ssm_client().get_parameter(SLACK_V2_API_KEY_PARAMETER_NAME)
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

    def get_sns_client(self) -> AwsSnsClient:
        return AwsClientFactory().get_sns_client()

    def get_ssm_client(self) -> AwsSsmClient:
        return AwsClientFactory().get_ssm_client()

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
