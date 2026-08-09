from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.auth.router import router as auth_router
from app.core.config import get_settings
from app.core.database import check_database_connection
from app.core.exceptions import AppError
from app.metrics.router import router as metrics_router
from app.orders.router import router as orders_router
from app.products.router import router as products_router

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description=(
        "API REST para autenticación, consulta de productos "
        "y gestión transaccional de pedidos."
    ),
)

app.include_router(auth_router)
app.include_router(products_router)
app.include_router(orders_router)
app.include_router(metrics_router)


@app.exception_handler(AppError)
async def app_error_handler(
    request: Request,
    exc: AppError,
) -> JSONResponse:
    del request

    content: dict[str, object] = {
        "code": exc.code,
        "message": exc.message,
    }

    if exc.details is not None:
        content["details"] = exc.details
    headers = None
    if exc.status_code == status.HTTP_401_UNAUTHORIZED:
        headers = {"WWW-Authenticate": "Bearer"}
    return JSONResponse(
        status_code=exc.status_code,
        content=content,
        headers=headers,
    )


@app.exception_handler(RequestValidationError)
async def validation_error_handler(
    request: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    del request

    errors = []

    for error in exc.errors():
        errors.append(
            {
                "field": ".".join(str(part) for part in error["loc"]),
                "message": error["msg"],
                "type": error["type"],
            }
        )

    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
        content={
            "code": "VALIDATION_ERROR",
            "message": "La solicitud contiene datos inválidos.",
            "details": errors,
        },
    )


@app.get("/health", tags=["Salud"])
def health_check() -> dict[str, str]:
    return {
        "status": "ok",
        "service": settings.app_name,
        "version": settings.app_version,
    }


@app.get("/health/ready", tags=["Salud"])
def readiness_check() -> dict[str, str]:
    try:
        check_database_connection()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "code": "DATABASE_UNAVAILABLE",
                "message": "La base de datos no se encuentra disponible.",
            },
        ) from exc

    return {
        "status": "ready",
        "database": settings.db_name,
    }
