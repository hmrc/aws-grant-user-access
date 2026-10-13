from typing import Any, Dict, List
from aws_grant_user_access.src.clients.slack_client import SlackClient
from aws_grant_user_access.src.data.data import AWS_IAM_TIME_FORMAT

from aws_grant_user_access.src.grant_time_window import GrantTimeWindow

SLACK_DISPLAY_NAME = "grant-user-access"
SLACK_EMOJI = ":unlock:"


class SlackMessage:
    def __init__(
        self,
        role_arn: str,
        usernames: List[str],
        hours: int,
        time_window: GrantTimeWindow,
        dry_run: bool = False,
    ) -> None:
        self.role_arn = role_arn
        self.usernames = usernames
        self.hours = hours
        self.time_window = time_window
        self.dry_run = dry_run

    def text(self) -> str:
        if self.dry_run:
            return self._dry_run_text()
        return self._grant_text()

    def _grant_text(self) -> str:
        return f"Temporary access to user(s) granted\n{self._grant_details()}"

    def _dry_run_text(self) -> str:
        return (
            "[DRY RUN] Temporary access to user(s) granted\n"
            f"{self._grant_details()}\n"
            "_This is a dry run test - no access was granted._"
        )

    def _grant_details(self) -> str:
        start_time = self.time_window.start_time.strftime(AWS_IAM_TIME_FORMAT)
        end_time = self.time_window.end_time.strftime(AWS_IAM_TIME_FORMAT)
        users = "\n".join(f"  *  {username}" for username in self.usernames)
        return (
            f"Access to `{self.role_arn}` has been granted for {self.hours} hour(s) "
            f"to the following users at {start_time}:\n"
            f"{users}\n"
            f"Access expires at {end_time}."
        )


class SlackMessagePublisher:
    def __init__(self, slack_client: SlackClient) -> None:
        self.slack_client = slack_client

    def publish_slack_message(self, channels: List[str], message: SlackMessage) -> Dict[str, Any]:
        return self.slack_client.post(
            channels=channels, display_name=SLACK_DISPLAY_NAME, emoji=SLACK_EMOJI, text=message.text()
        )
