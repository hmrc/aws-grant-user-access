from datetime import datetime, timedelta
from typing import Any


class GrantTimeWindow:
    def __init__(self, hours: str) -> None:
        self.__now = datetime.utcnow()
        self.__hours = hours

    @property
    def start_time(self) -> str:
        return self.__now

    @property
    def end_time(self) -> str:
        return self.__now + timedelta(hours=self.__hours)
