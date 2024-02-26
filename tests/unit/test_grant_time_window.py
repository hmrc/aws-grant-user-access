from datetime import datetime, timedelta
from typing import Any, Dict, List
from freezegun import freeze_time
from aws_grant_user_access.src.grant_time_window import GrantTimeWindow


@freeze_time("2012-06-21 12:00:01")
def test_time_window_start_time() -> None:
    grant_time_window = GrantTimeWindow(hours=1)
    assert grant_time_window.start_time == datetime.utcnow()
    assert grant_time_window.start_time == datetime(year=2012, month=6, day=21, hour=12, minute=0, second=1)


@freeze_time("2012-06-27 12:00:01")
def test_time_window_end_time() -> None:
    test_cases: List[Dict[str, Any]] = [
        {"approval_in_hours": 0.1, "end_time": datetime(year=2012, month=6, day=27, hour=12, minute=6, second=1)},
        {"approval_in_hours": 0.5, "end_time": datetime(year=2012, month=6, day=27, hour=12, minute=30, second=1)},
        {"approval_in_hours": 1, "end_time": datetime(year=2012, month=6, day=27, hour=13, minute=0, second=1)},
        {"approval_in_hours": 2, "end_time": datetime(year=2012, month=6, day=27, hour=14, minute=0, second=1)},
    ]

    for tc in test_cases:
        print(f"test case: {tc['approval_in_hours'] = }")
        grant_time_window = GrantTimeWindow(hours=tc["approval_in_hours"])
        assert grant_time_window.start_time == datetime(year=2012, month=6, day=27, hour=12, minute=0, second=1)
        assert grant_time_window.end_time == tc["end_time"]
