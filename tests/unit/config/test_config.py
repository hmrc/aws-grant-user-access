from aws_grant_user_access.src.data.exceptions import InvalidConfigException
import pytest
from typing import Any
from aws_grant_user_access.src.config.config import Config


def test_get_default_log_level(monkeypatch: Any) -> None:
    monkeypatch.delenv("LOG_LEVEL", raising=False)

    assert Config.get_log_level() == "WARNING"


def test_get_invalid_log_level(monkeypatch: Any) -> None:
    monkeypatch.setenv("LOG_LEVEL", "PANIC")
    with pytest.raises(InvalidConfigException) as ice:
        Config.get_log_level()

    assert str(ice.value) == "invalid LOG_LEVEL: PANIC"
