from typing import Annotated

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.auth.models import AuthUser
from app.auth.repository import AuthRepository
from app.core.database import get_db
from app.core.exceptions import (
    AuthenticationRequiredError,
    InvalidTokenError,
    UserInactiveError,
)
from app.core.security import decode_access_token

bearer_scheme = HTTPBearer(
    auto_error=False,
    description="Ingresá el JWT obtenido desde POST /api/v1/auth/login.",
)

DatabaseSession = Annotated[Session, Depends(get_db)]
BearerCredentials = Annotated[
    HTTPAuthorizationCredentials | None,
    Depends(bearer_scheme),
]


def get_current_user(
    credentials: BearerCredentials,
    db: DatabaseSession,
) -> AuthUser:
    """Valida el JWT y comprueba que el usuario continúe activo."""

    if credentials is None:
        raise AuthenticationRequiredError()

    if credentials.scheme.lower() != "bearer":
        raise InvalidTokenError()

    payload = decode_access_token(credentials.credentials)
    subject = payload["sub"]

    try:
        user_id = int(subject)
    except (TypeError, ValueError) as exc:
        raise InvalidTokenError() from exc

    repository = AuthRepository(db)
    user = repository.find_by_id(user_id)

    if user is None:
        raise InvalidTokenError()

    if not user.is_active:
        raise UserInactiveError()

    return user


CurrentUser = Annotated[AuthUser, Depends(get_current_user)]
