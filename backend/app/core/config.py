from functools import lru_cache

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuración de la aplicación obtenida desde variables de entorno."""

    app_name: str = "Xionico Orders API"
    app_version: str = "1.0.0"
    app_env: str = "development"

    db_host: str
    db_port: int = 1433
    db_name: str
    db_user: str
    db_password: SecretStr
    db_driver: str = "ODBC Driver 18 for SQL Server"
    db_encrypt: bool = True
    db_trust_server_certificate: bool = True

    jwt_secret_key: SecretStr
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 60
    default_customer_code: str = "CUST-DEFAULT"
    max_order_items: int = 50
    max_item_quantity: int = 10000

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    """
    Devuelve una única instancia de configuración.

    El caché evita volver a leer y validar el archivo .env
    en cada request.
    """
    return Settings()
