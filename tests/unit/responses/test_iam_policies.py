LIST_POLICIES = {
    "Policies": [
        {
            "PolicyName": "test-user-3_1693482856.642057",
            "Arn": "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057",
            "DefaultVersionId": "foo",
        },
        {
            "PolicyName": "to_keep",
            "Arn": "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/to_keep",
            "DefaultVersionId": "v1",
        },
        {
            "PolicyName": "to_keep_2",
            "Arn": "arn:aws:iam::123456789012:policy/to_keep_2",
            "DefaultVersionId": "v1",
        },
        {
            "PolicyName": "test-user-4_1693482856.642057",
            "Arn": "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-4_1693482856.642057",
            "DefaultVersionId": "v1",
        },
    ],
}

POLICIES_MAP = {
    "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057": {
        "Policy": {
            "PolicyName": "test-user-3_1693482856.642057",
            "PolicyId": "ABCDEFGHIJKLMNOP01234",
            "Arn": "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057",
            "Path": "/Lambda/GrantUserAccess/",
            "DefaultVersionId": "v1",
            "AttachmentCount": 1,
            "PermissionsBoundaryUsageCount": 0,
            "IsAttachable": "true",
            "Description": "An IAM policy to grant-user-access to assume a role",
            "CreateDate": "2020-05-01T00:00:00+00:00",
            "UpdateDate": "2020-05-01T00:00:00+00:00",
            "Tags": [
                {"Key": "Expires_At", "Value": "2020-05-02T00:00:00Z"},
                {"Key": "Product", "Value": "grant-user-access"},
            ],
        },
    },
    "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/to_keep": {
        "Policy": {
            "PolicyName": "to_keep",
            "PolicyId": "ABCDEFGHIJKLMNOP12345",
            "Arn": "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/to_keep",
            "Path": "/Lambda/GrantUserAccess/",
            "DefaultVersionId": "v1",
            "AttachmentCount": 1,
            "PermissionsBoundaryUsageCount": 0,
            "IsAttachable": "true",
            "Description": "An IAM policy to grant-user-access to assume a role",
            "CreateDate": "2023-05-01T00:00:00+00:00",
            "UpdateDate": "2023-05-01T00:00:00+00:00",
            "Tags": [
                {"Key": "Expires_At", "Value": "2023-05-01T00:00:00Z"},
                {"Key": "Product", "Value": "grant-user-access"},
            ],
        },
    },
    "arn:aws:iam::123456789012:policy/to_keep_2": {
        "Policy": {
            "PolicyName": "to_keep_2",
            "PolicyId": "ABCDEFGHIJKLMNOP23456",
            "Arn": "arn:aws:iam::123456789012:policy/to_keep_2",
            "Path": "/Lambda/GrantUserAccess/",
            "DefaultVersionId": "v1",
            "AttachmentCount": 1,
            "PermissionsBoundaryUsageCount": 0,
            "IsAttachable": "true",
            "Description": "An IAM policy to grant-user-access to assume a role",
            "CreateDate": "2023-05-01T00:00:00+00:00",
            "UpdateDate": "2023-05-01T00:00:00+00:00",
            "Tags": [
                {"Key": "Expires_At", "Value": "2023-05-01T00:00:00Z"},
            ],
        },
    },
    "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-4_1693482856.642057": {
        "Policy": {
            "PolicyName": "test-user-4_1693482856.642057",
            "PolicyId": "ABCDEFGHIJKLMNOP01234",
            "Arn": "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-4_1693482856.642057",
            "Path": "/Lambda/GrantUserAccess/",
            "DefaultVersionId": "v1",
            "AttachmentCount": 1,
            "PermissionsBoundaryUsageCount": 0,
            "IsAttachable": "true",
            "Description": "An IAM policy to grant-user-access to assume a role",
            "CreateDate": "2021-01-01T01:01:00+00:00",
            "UpdateDate": "2021-01-01T01:01:00+00:00",
            "Tags": [
                {"Key": "Expires_At", "Value": "2021-01-01T01:01:00Z"},
                {"Key": "Product", "Value": "grant-user-access"},
            ],
        },
    },
}

LIST_ATTACHED_USER_POLICIES = [
    {
        "PolicyName": "test-user-3_1693482856.642057",
        "PolicyArn": "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-3_1693482856.642057",
    },
    {
        "PolicyName": "test-user-4_1693482856.642057",
        "PolicyArn": "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/test-user-4_1693482856.642057",
    },
    {
        "PolicyName": "to_keep",
        "PolicyArn": "arn:aws:iam::123456789012:policy/Lambda/GrantUserAccess/to_keep",
    },
]
