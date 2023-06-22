from datetime import datetime, UTC

from aws_grant_user_access.src.policy_creator import PolicyCreator

def test_policy_creator_generate_policy_document():
    policy_creator = PolicyCreator()
    policy_document = policy_creator.generate_policy_document(
        role_arn="aws:::test",
        start_time=datetime(year=2020, month=5, day=1, hour=0, minute=0, second=0, tzinfo=UTC),
        end_time=datetime(year=2020, month=5, day=1, hour=23, minute=59, second=59, tzinfo=UTC)
    )

    expected_result = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "sts:AssumeRole",
                "Resource": "aws:::test",
                "Condition": {
                    "DateGreaterThan": {"aws:CurrentTime": "2020-05-01T00:00:00Z"},
                    "DateLessThan": {"aws:CurrentTime": "2020-05-01T23:59:59Z"}
                }
            }
        ]
    }

    assert policy_document == expected_result



