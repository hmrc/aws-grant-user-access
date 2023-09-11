from datetime import datetime, timedelta
from freezegun import freeze_time
from aws_grant_user_access.src.grant_time_window import GrantTimeWindow


@freeze_time("2012-06-21 12:00:01")
def test_time_window() -> None:
    grant_time_window = GrantTimeWindow(hours=1)
    print(grant_time_window.start_time)
    print(datetime.utcnow())
    assert grant_time_window.start_time == datetime.utcnow()
    assert grant_time_window.start_time == datetime(year=2012, month=6, day=21, hour=12, minute=0, second=1)


@freeze_time("2012-06-27 12:00:01")
def test_time_window_end_time() -> None:
    grant_time_window = GrantTimeWindow(hours=2)
    assert grant_time_window.start_time == datetime(year=2012, month=6, day=27, hour=12, minute=0, second=1)
    assert grant_time_window.end_time == datetime(year=2012, month=6, day=27, hour=14, minute=0, second=1)
