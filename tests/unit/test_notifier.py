from unittest.mock import Mock
from aws_grant_user_access.src.notifier import SlackMessage, SlackMessagePublisher
from aws_grant_user_access.src.grant_time_window import GrantTimeWindow
from freezegun import freeze_time


@freeze_time("2012-01-14 12:00:01")
def test_slack_message_text() -> None:
    message = SlackMessage(
        role_arn="arn:aws:iam::123456789012:role/RoleTerraformApplier",
        usernames=["test.user"],
        hours=2,
        time_window=GrantTimeWindow(hours=2),
    )

    assert message.text() == (
        "Temporary access to user(s) granted\n"
        "Access to `arn:aws:iam::123456789012:role/RoleTerraformApplier` has been granted for 2 hour(s) "
        "to the following users at 2012-01-14T12:00:01Z:\n"
        "  *  test.user\n"
        "Access expires at 2012-01-14T14:00:01Z."
    )


@freeze_time("2012-01-14 12:00:01")
def test_publish_slack_message() -> None:
    message = SlackMessage(
        role_arn="arn:aws:iam::123456789012:role/RoleTerraformApplier",
        usernames=["test.user"],
        hours=2,
        time_window=GrantTimeWindow(hours=2),
    )
    slack_client = Mock(post=Mock(return_value={}))

    response = SlackMessagePublisher(slack_client).publish_slack_message(channels=["#a-channel"], message=message)

    slack_client.post.assert_called_once_with(
        channels=["#a-channel"], display_name="grant-user-access", emoji=":unlock:", text=message.text()
    )
    assert response == {}
