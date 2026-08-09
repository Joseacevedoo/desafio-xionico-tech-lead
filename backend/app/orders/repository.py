from uuid import UUID

from sqlalchemy import text
from sqlalchemy.exc import DBAPIError
from sqlalchemy.orm import Session

from app.core.exceptions import (
    DefaultCustomerNotFoundError,
    IdempotencyKeyConflictError,
    InsufficientStockError,
    OrderCreationError,
    ProductInactiveError,
    ProductNotFoundError,
)
from app.orders.models import (
    OrderDetail,
    OrderDetailItem,
    OrderSummary,
    RegisterOrderResult,
)


class OrderRepository:
    """Acceso a datos requerido para registrar y consultar pedidos."""

    def __init__(self, db: Session) -> None:
        self._db = db

    def find_active_customer_id_by_code(
        self,
        code: str,
    ) -> int | None:
        statement = text(
            """
            SELECT customer_id
            FROM dbo.customers
            WHERE code = :code
              AND is_active = 1;
            """
        )

        result = self._db.execute(
            statement,
            {"code": code},
        ).scalar_one_or_none()

        return int(result) if result is not None else None

    def count_orders(self) -> int:
        statement = text(
            """
            SELECT COUNT_BIG(*) AS total_items
            FROM dbo.orders;
            """
        )

        result = self._db.execute(statement).scalar_one()

        return int(result)

    def list_orders(
        self,
        *,
        offset: int,
        page_size: int,
    ) -> list[OrderSummary]:
        statement = text(
            """
            SELECT
                o.order_id,
                o.order_number,
                o.status,
                o.currency_code,
                o.total_amount,
                o.created_at,

                c.customer_id,
                c.code AS customer_code,
                c.name AS customer_name,

                COALESCE(items.total_units, 0) AS total_units

            FROM dbo.orders AS o

            INNER JOIN dbo.customers AS c
                ON c.customer_id = o.customer_id

            LEFT JOIN (
                SELECT
                    order_id,
                    SUM(quantity) AS total_units
                FROM dbo.order_items
                GROUP BY order_id
            ) AS items
                ON items.order_id = o.order_id

            ORDER BY o.created_at DESC, o.order_id DESC
            OFFSET :offset ROWS
            FETCH NEXT :page_size ROWS ONLY;
            """
        )

        rows = (
            self._db.execute(
                statement,
                {
                    "offset": offset,
                    "page_size": page_size,
                },
            )
            .mappings()
            .all()
        )

        return [
            OrderSummary(
                order_id=row["order_id"],
                order_number=row["order_number"],
                status=row["status"],
                currency_code=row["currency_code"],
                total_amount=row["total_amount"],
                created_at=row["created_at"],
                customer_id=row["customer_id"],
                customer_code=row["customer_code"],
                customer_name=row["customer_name"],
                total_units=int(row["total_units"]),
            )
            for row in rows
        ]

    def register_order(
        self,
        *,
        user_id: int,
        customer_id: int,
        idempotency_key: UUID,
        request_hash: str,
        items_json: str,
    ) -> RegisterOrderResult:
        statement = text(
            """
            EXEC dbo.sp_RegisterOrder
                @user_id = :user_id,
                @customer_id = :customer_id,
                @idempotency_key = :idempotency_key,
                @request_hash = :request_hash,
                @items_json = :items_json;
            """
        )

        try:
            row = (
                self._db.execute(
                    statement,
                    {
                        "user_id": user_id,
                        "customer_id": customer_id,
                        "idempotency_key": str(idempotency_key),
                        "request_hash": request_hash,
                        "items_json": items_json,
                    },
                )
                .mappings()
                .one()
            )

            # Confirma la transacción manejada por la sesión de SQLAlchemy.
            self._db.commit()

        except DBAPIError as exc:
            self._db.rollback()
            self._raise_mapped_database_error(exc)

        except Exception:
            self._db.rollback()
            raise

        return RegisterOrderResult(
            order_id=int(row["order_id"]),
            order_number=str(row["order_number"]),
            total_amount=row["total_amount"],
            is_replay=bool(row["is_replay"]),
        )

    def get_order_by_id(
        self,
        order_id: int,
    ) -> OrderDetail | None:
        header_statement = text(
            """
            SELECT
                o.order_id,
                o.order_number,
                o.status,
                o.currency_code,
                o.total_amount,
                o.created_at,

                c.customer_id,
                c.code AS customer_code,
                c.name AS customer_name,

                u.user_id AS created_by_user_id,
                u.username AS created_by_username,
                u.display_name AS created_by_display_name

            FROM dbo.orders AS o

            INNER JOIN dbo.customers AS c
                ON c.customer_id = o.customer_id

            INNER JOIN dbo.users AS u
                ON u.user_id = o.created_by_user_id

            WHERE o.order_id = :order_id;
            """
        )

        header = (
            self._db.execute(
                header_statement,
                {"order_id": order_id},
            )
            .mappings()
            .first()
        )

        if header is None:
            return None

        items_statement = text(
            """
            SELECT
                oi.product_id,
                p.code AS product_code,
                p.name AS product_name,
                oi.quantity,
                oi.unit_price,
                oi.subtotal

            FROM dbo.order_items AS oi

            INNER JOIN dbo.products AS p
                ON p.product_id = oi.product_id

            WHERE oi.order_id = :order_id

            ORDER BY oi.order_item_id ASC;
            """
        )

        item_rows = (
            self._db.execute(
                items_statement,
                {"order_id": order_id},
            )
            .mappings()
            .all()
        )

        items = [
            OrderDetailItem(
                product_id=row["product_id"],
                product_code=row["product_code"],
                product_name=row["product_name"],
                quantity=row["quantity"],
                unit_price=row["unit_price"],
                subtotal=row["subtotal"],
            )
            for row in item_rows
        ]

        return OrderDetail(
            order_id=header["order_id"],
            order_number=header["order_number"],
            status=header["status"],
            currency_code=header["currency_code"],
            total_amount=header["total_amount"],
            created_at=header["created_at"],
            customer_id=header["customer_id"],
            customer_code=header["customer_code"],
            customer_name=header["customer_name"],
            created_by_user_id=header["created_by_user_id"],
            created_by_username=header["created_by_username"],
            created_by_display_name=header["created_by_display_name"],
            items=items,
        )

    @staticmethod
    def _raise_mapped_database_error(
        exc: DBAPIError,
    ) -> None:
        database_message = str(exc.orig).upper()

        if "IDEMPOTENCY_KEY_CONFLICT" in database_message:
            raise IdempotencyKeyConflictError() from exc

        if "PRODUCT_NOT_FOUND" in database_message:
            raise ProductNotFoundError() from exc

        if "PRODUCT_INACTIVE" in database_message:
            raise ProductInactiveError() from exc

        if "INSUFFICIENT_STOCK" in database_message:
            raise InsufficientStockError() from exc

        if "CUSTOMER_NOT_FOUND_OR_INACTIVE" in database_message:
            raise DefaultCustomerNotFoundError() from exc

        raise OrderCreationError() from exc
