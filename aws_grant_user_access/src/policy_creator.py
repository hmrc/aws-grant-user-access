AWS_IAM_TIME_FORMAT = "%Y-%m-%dT%H:%M:%SZ"


class PolicyCreator:


    def grant_access(self, username, start_time='someimte now', endtime="sometime 12 hours later"):
        pass

    def create_iam_policy(self, policy_document ):
        pass

    def generate_policy_document(self, role_arn, start_time, end_time):
        policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": "sts:AssumeRole",
                    "Resource": role_arn,
                    "Condition": {
                        "DateGreaterThan": {"aws:CurrentTime": start_time.strftime(AWS_IAM_TIME_FORMAT)},
                        "DateLessThan": {"aws:CurrentTime": end_time.strftime(AWS_IAM_TIME_FORMAT)}
                    }
                }
            ]
        }

        return policy

    def attach_policy_to_user(self, policy_document_arn, username):
        pass

