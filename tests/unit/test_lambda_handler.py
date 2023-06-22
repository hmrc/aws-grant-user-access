from aws_grant_user_access.src.main import handle


def test_handler_takes_events():
    handle(dict(test=1), dict(context=1))
