from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class AuthUser:
    """Usuario recuperado desde SQL Server para autenticación."""

    user_id: int
    username: str
    display_name: str
    password_hash: str
    is_active: bool
