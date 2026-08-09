from pwdlib import PasswordHash

from app.core.security import verify_password


def test_verify_password_accepts_valid_password() -> None:
    password_hash = PasswordHash.recommended()

    plain_password = "Demo123!"
    hashed_password = password_hash.hash(plain_password)

    assert (
        verify_password(
            plain_password,
            hashed_password,
        )
        is True
    )


def test_verify_password_rejects_invalid_password() -> None:
    password_hash = PasswordHash.recommended()

    hashed_password = password_hash.hash("Demo123!")

    assert (
        verify_password(
            "Incorrecta",
            hashed_password,
        )
        is False
    )


def test_verify_password_rejects_invalid_hash() -> None:
    assert (
        verify_password(
            "Demo123!",
            "esto-no-es-un-hash-valido",
        )
        is False
    )
