from collections.abc import Generator

from sqlalchemy import URL, Engine, create_engine, text
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import get_settings

settings = get_settings()

database_url = URL.create(
    drivername="mssql+pyodbc",
    username=settings.db_user,
    password=settings.db_password.get_secret_value(),
    host=settings.db_host,
    port=settings.db_port,
    database=settings.db_name,
    query={
        "driver": settings.db_driver,
        "Encrypt": "yes" if settings.db_encrypt else "no",
        "TrustServerCertificate": (
            "yes" if settings.db_trust_server_certificate else "no"
        ),
    },
)

engine: Engine = create_engine(
    database_url,
    pool_pre_ping=True,
    pool_recycle=1800,
)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
    expire_on_commit=False,
)


def get_db() -> Generator[Session, None, None]:
    """Entrega una sesión y garantiza su cierre al finalizar la request."""

    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


def check_database_connection() -> None:
    """Ejecuta una consulta mínima para comprobar conectividad."""

    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))
