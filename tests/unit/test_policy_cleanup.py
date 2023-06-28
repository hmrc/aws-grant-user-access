from aws_grant_user_access.src.expired_policy_cleaner import ExpiredPolicyCleaner


def test_expired_policies_are_removed():
    expired_policy_cleaner = ExpiredPolicyCleaner()
