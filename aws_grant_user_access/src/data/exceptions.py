class GrantUserAccessException(Exception):
    pass


class AwsClientException(GrantUserAccessException):
    pass


class ClientFactoryException(GrantUserAccessException):
    pass

class MissingConfigException(GrantUserAccessException):
    pass


class InvalidConfigException(GrantUserAccessException):
    pass