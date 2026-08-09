from typing import Any

from fastapi import status


class AppError(Exception):
    """Excepción controlada que puede transformarse en una respuesta HTTP."""

    def __init__(
        self,
        *,
        status_code: int,
        code: str,
        message: str,
        details: Any | None = None,
    ) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.code = code
        self.message = message
        self.details = details


class InvalidCredentialsError(AppError):
    def __init__(self) -> None:
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="INVALID_CREDENTIALS",
            message="Usuario o contraseña incorrectos.",
        )


class AuthenticationRequiredError(AppError):
    def __init__(self) -> None:
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="AUTHENTICATION_REQUIRED",
            message="Se requiere autenticación.",
        )


class InvalidTokenError(AppError):
    def __init__(self) -> None:
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="INVALID_TOKEN",
            message="El token de autenticación no es válido.",
        )


class TokenExpiredError(AppError):
    def __init__(self) -> None:
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="TOKEN_EXPIRED",
            message="La sesión ha expirado.",
        )


class UserInactiveError(AppError):
    def __init__(self) -> None:
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="USER_INACTIVE",
            message="El usuario no se encuentra habilitado.",
        )


class DefaultCustomerNotFoundError(AppError):
    def __init__(self) -> None:
        super().__init__(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            code="DEFAULT_CUSTOMER_NOT_CONFIGURED",
            message="El cliente predeterminado no está disponible.",
        )


class DuplicateProductError(AppError):
    def __init__(self, product_id: int | None = None) -> None:
        details = {"product_id": product_id} if product_id is not None else None

        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            code="DUPLICATE_PRODUCT",
            message="Un producto aparece más de una vez en el pedido.",
            details=details,
        )


class IdempotencyKeyConflictError(AppError):
    def __init__(self) -> None:
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            code="IDEMPOTENCY_KEY_CONFLICT",
            message=("La clave de idempotencia ya fue utilizada para otra operación."),
        )


class ProductNotFoundError(AppError):
    def __init__(self) -> None:
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            code="PRODUCT_NOT_FOUND",
            message="Uno o más productos no existen.",
        )


class ProductInactiveError(AppError):
    def __init__(self) -> None:
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            code="PRODUCT_INACTIVE",
            message="Uno o más productos no están disponibles.",
        )


class InsufficientStockError(AppError):
    def __init__(self) -> None:
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            code="INSUFFICIENT_STOCK",
            message="No hay stock suficiente para completar el pedido.",
        )


class OrderCreationError(AppError):
    def __init__(self) -> None:
        super().__init__(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            code="ORDER_CREATION_ERROR",
            message="No fue posible registrar el pedido.",
        )


class OrderNotFoundError(AppError):
    def __init__(self) -> None:
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            code="ORDER_NOT_FOUND",
            message="El pedido solicitado no existe.",
        )
