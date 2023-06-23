from datetime import datetime


class GrantTimeWindow:

    def __init__(self, hours):
        pass

    @property
    def start_time(self):
        return datetime.utcnow()
