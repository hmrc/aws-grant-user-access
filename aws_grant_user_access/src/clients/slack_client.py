import json
from typing import Any, Dict, List

import requests

from aws_grant_user_access.src.data.exceptions import SlackNotificationException

TIMEOUT_SECONDS = 10


class SlackClient:
    def __init__(self, webhook_url: str, api_key: str) -> None:
        self._webhook_url = webhook_url
        self._api_key = api_key

    def post(self, channels: List[str], display_name: str, emoji: str, text: str) -> Dict[str, Any]:
        payload = {
            "channelLookup": {"by": "slack-channel", "slackChannels": channels},
            "displayName": display_name,
            "emoji": emoji,
            "text": text,
        }

        try:
            response = requests.post(
                url=self._webhook_url,
                data=json.dumps(payload),
                headers={"Content-Type": "application/json", "Authorization": self._api_key},
                timeout=TIMEOUT_SECONDS,
            )
            response.raise_for_status()
            response_body = dict(response.json())
        except requests.RequestException as err:
            raise SlackNotificationException(f"failed to post message to slack channels {channels}: {err}") from None

        errors = response_body.get("errors")
        if errors:
            raise SlackNotificationException(f"slack rejected message to channels {channels}: {errors}")

        return response_body
