from typing import Callable
from aws_grant_user_access.src import T
from aws_grant_user_access.src.data.exceptions import AwsClientException

from botocore.exceptions import BotoCoreError, ClientError

def boto_try(func: Callable[[], T], except_msg: str) -> T:
    try:
        return func()
    except (BotoCoreError, ClientError, TypeError, ValueError) as err:
        raise AwsClientException(f"{except_msg}: {err}") from None
