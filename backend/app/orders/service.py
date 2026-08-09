import hashlib
import json
from math import ceil
from uuid import UUID

from app.auth.models import AuthUser
from app.core.config import get_settings
from app.core.exceptions import (
    DefaultCustomerNotFoundError,
    DuplicateProductError,
    OrderNotFoundError,
)
from app.orders.models import (
    OrderDetail,
    OrderItemInput,
    OrderListResult,
    RegisterOrderResult,
)
from app.orders.repository import OrderRepository

settings = get_settings()


class OrderService:
    """Caso de uso para registrar pedidos."""

    def __init__(
        self,
        repository: OrderRepository,
    ) -> None:
        self._repository = repository

    def get_order(
        self,
        *,
        order_id: int,
    ) -> OrderDetail:
        order = self._repository.get_order_by_id(order_id)

        if order is None:
            raise OrderNotFoundError()

        return order

    def list_orders(
        self,
        *,
        page: int,
        page_size: int,
    ) -> OrderListResult:
        offset = (page - 1) * page_size
        total_items = self._repository.count_orders()
        items = self._repository.list_orders(
            offset=offset,
            page_size=page_size,
        )
        total_pages = ceil(total_items / page_size) if total_items > 0 else 0

        return OrderListResult(
            items=items,
            page=page,
            page_size=page_size,
            total_items=total_items,
            total_pages=total_pages,
        )

    def create_order(
        self,
        *,
        current_user: AuthUser,
        idempotency_key: UUID,
        items: list[OrderItemInput],
    ) -> RegisterOrderResult:
        self._validate_no_duplicates(items)

        customer_id = self._repository.find_active_customer_id_by_code(
            settings.default_customer_code
        )

        if customer_id is None:
            raise DefaultCustomerNotFoundError()

        canonical_items = sorted(
            items,
            key=lambda item: item.product_id,
        )

        payload = [
            {
                "product_id": item.product_id,
                "quantity": item.quantity,
            }
            for item in canonical_items
        ]

        items_json = json.dumps(
            payload,
            ensure_ascii=False,
            separators=(",", ":"),
        )

        request_hash = hashlib.sha256(items_json.encode("utf-8")).hexdigest().upper()

        return self._repository.register_order(
            user_id=current_user.user_id,
            customer_id=customer_id,
            idempotency_key=idempotency_key,
            request_hash=request_hash,
            items_json=items_json,
        )

    @staticmethod
    def _validate_no_duplicates(
        items: list[OrderItemInput],
    ) -> None:
        seen: set[int] = set()

        for item in items:
            if item.product_id in seen:
                raise DuplicateProductError(product_id=item.product_id)

            seen.add(item.product_id)
