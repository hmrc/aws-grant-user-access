from datetime import datetime, timedelta
from freezegun import freeze_time
from aws_grant_user_access.src.grant_time_window import GrantTimeWindow

@freeze_time('2023-06-21')
def test_time_window():
    grant_time_window = GrantTimeWindow(hours=1)
    assert grant_time_window.start_time == datetime.utcnow()

def test_time_window_end_time():
    grant_time_window = GrantTimeWindow(hours=1)
    assert grant_time_window.end_time == datetime.utcnow() + timedelta(1)
