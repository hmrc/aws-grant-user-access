from datetime import datetime
from freezegun import freeze_time
from aws_grant_user_access.src.grant_time_window import GrantTimeWindow

@freeze_time('2023-06-21')
def test_time_window():
    grant_time_window = GrantTimeWindow(hours=1)
    assert grant_time_window.start_time == datetime.utcnow()
