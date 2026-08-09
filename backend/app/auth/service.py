from dataclasses import dataclass

from app.auth.models import AuthUser
from app.auth.repository import AuthRepository
from app.core.config import get_settings
from app.core.exceptions import InvalidCredentialsError
from app.core.security import create_access_token, verify_password

settings = get_settings()


@dataclass(frozen=True, slots=True)
class LoginResult:
    access_token: str
    expires_in: int
    user: AuthUser


class AuthService:
    """Caso de uso de autenticación de operadores."""

    def __init__(self, repository: AuthRepository) -> None:
        self._repository = repository

    def login(
        self,
        *,
        username: str,
        password: str,
    ) -> LoginResult:
        normalized_username = username.strip()

        user = self._repository.find_by_username(normalized_username)

        if (
            user is None
            or not user.is_active
            or not verify_password(
                password,
                user.password_hash,
            )
        ):
            raise InvalidCredentialsError()

        token = create_access_token(
            subject=str(user.user_id),
            username=user.username,
        )

        return LoginResult(
            access_token=token,
            expires_in=(settings.jwt_access_token_expire_minutes * 60),
            user=user,
        )
