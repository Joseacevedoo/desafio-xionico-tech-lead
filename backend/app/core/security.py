from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
from jwt import ExpiredSignatureError
from jwt import InvalidTokenError as PyJWTInvalidTokenError
from pwdlib import PasswordHash

from app.core.config import get_settings
from app.core.exceptions import InvalidTokenError, TokenExpiredError

settings = get_settings()
password_hash = PasswordHash.recommended()


def verify_password(
    plain_password: str,
    hashed_password: str,
) -> bool:
    """Verifica una contraseña sin intentar descifrar el hash."""

    try:
        return password_hash.verify(
            plain_password,
            hashed_password,
        )
    except Exception:
        # Un hash corrupto o incompatible no debe provocar un error 500
        # durante el inicio de sesión.
        return False


def create_access_token(
    *,
    subject: str,
    username: str,
) -> str:
    """Genera un JWT de acceso firmado con expiración controlada."""

    issued_at = datetime.now(UTC)
    expires_at = issued_at + timedelta(minutes=settings.jwt_access_token_expire_minutes)

    payload: dict[str, Any] = {
        "sub": subject,
        "username": username,
        "iat": issued_at,
        "exp": expires_at,
    }

    return jwt.encode(
        payload,
        settings.jwt_secret_key.get_secret_value(),
        algorithm=settings.jwt_algorithm,
    )


def decode_access_token(token: str) -> dict[str, Any]:
    """Valida firma, algoritmo y expiración del JWT."""

    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key.get_secret_value(),
            algorithms=[settings.jwt_algorithm],
        )
    except ExpiredSignatureError as exc:
        raise TokenExpiredError() from exc
    except PyJWTInvalidTokenError as exc:
        raise InvalidTokenError() from exc

    subject = payload.get("sub")

    if not isinstance(subject, str) or not subject.isdigit():
        raise InvalidTokenError()

    return payload
