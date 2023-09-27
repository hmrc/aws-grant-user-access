from typing import Any, Dict
from aws_grant_user_access.src.process_event import process_event


def handle(event: Dict[str, Any], context: Any) -> None:
    process_event(event, context)
