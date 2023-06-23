from datetime import datetime

from aws_grant_user_access.src.grant_time_window import GrantTimeWindow
def test_time_window():
    grant_time_window = GrantTimeWindow(hours=1)
    assert grant_time_window.start_time == datetime.utcnow()
