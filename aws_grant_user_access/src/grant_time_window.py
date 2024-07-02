from datetime import datetime, timedelta


class GrantTimeWindow:
    def __init__(self, hours: int) -> None:
        self.__now = datetime.utcnow()
        self.__hours = hours

    @property
    def start_time(self) -> datetime:
        return self.__now

    @property
    def end_time(self) -> datetime:
        return self.__now + timedelta(hours=self.__hours)
