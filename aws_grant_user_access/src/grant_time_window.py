from datetime import datetime, timedelta


class GrantTimeWindow:

    def __init__(self, hours):
        self.hours = hours

    @property
    def start_time(self):
        return datetime.utcnow()


    def end_time(self, start_time):
        return start_time + timedelta(self.hours)
