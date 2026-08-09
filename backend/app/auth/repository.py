from sqlalchemy import text
from sqlalchemy.orm import Session

from app.auth.models import AuthUser


class AuthRepository:
    """Acceso a datos requerido por el módulo de autenticación."""

    def __init__(self, db: Session) -> None:
        self._db = db

    def find_by_id(
        self,
        user_id: int,
    ) -> AuthUser | None:
        statement = text(
            """
                SELECT
                    user_id,
                    username,
                    display_name,
                    password_hash,
                    is_active
                FROM dbo.users
                WHERE user_id = :user_id
                """
        )

        row = (
            self._db.execute(
                statement,
                {"user_id": user_id},
            )
            .mappings()
            .first()
        )

        if row is None:
            return None

        return AuthUser(
            user_id=row["user_id"],
            username=row["username"],
            display_name=row["display_name"],
            password_hash=row["password_hash"],
            is_active=bool(row["is_active"]),
        )

    def find_by_username(
        self,
        username: str,
    ) -> AuthUser | None:
        statement = text(
            """
            SELECT
                user_id,
                username,
                display_name,
                password_hash,
                is_active
            FROM dbo.users
            WHERE username = :username
            """
        )

        row = (
            self._db.execute(
                statement,
                {"username": username},
            )
            .mappings()
            .first()
        )

        if row is None:
            return None

        return AuthUser(
            user_id=row["user_id"],
            username=row["username"],
            display_name=row["display_name"],
            password_hash=row["password_hash"],
            is_active=bool(row["is_active"]),
        )
