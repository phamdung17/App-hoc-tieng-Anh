"""
app/modules/auth/errors.py

Domain errors cho auth module.
"""


class AuthDomainError(Exception):
    def __init__(self, code: str, message: str = "") -> None:
        self.code = code
        self.message = message or code
        super().__init__(message or code)


class EmailAlreadyRegisteredError(AuthDomainError):
    def __init__(self) -> None:
        super().__init__("EMAIL_ALREADY_REGISTERED", "Email is already registered")


class InvalidCredentialsError(AuthDomainError):
    def __init__(self) -> None:
        super().__init__("INVALID_CREDENTIALS", "Incorrect email or password")


class UserNotFoundError(AuthDomainError):
    def __init__(self) -> None:
        super().__init__("USER_NOT_FOUND", "User not found")


class InvalidVerifyTokenError(AuthDomainError):
    def __init__(self) -> None:
        super().__init__("INVALID_VERIFY_TOKEN", "Verification token is invalid or expired")


class EmailAlreadyVerifiedError(AuthDomainError):
    def __init__(self) -> None:
        super().__init__("EMAIL_ALREADY_VERIFIED", "Email is already verified")
