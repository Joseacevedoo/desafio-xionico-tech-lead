from decimal import Decimal
from uuid import UUID

import pytest

from app.auth.models import AuthUser
from app.core.exceptions import DuplicateProductError
from app.orders.models import (
    OrderItemInput,
    RegisterOrderResult,
)
from app.orders.service import OrderService


class FakeOrderRepository:
    def __init__(self) -> None:
        self.received_items_json: str | None = None
        self.received_request_hash: str | None = None

    def find_active_customer_id_by_code(
        self,
        code: str,
    ) -> int | None:
        return 1

    def register_order(
        self,
        *,
        user_id: int,
        customer_id: int,
        idempotency_key: UUID,
        request_hash: str,
        items_json: str,
    ) -> RegisterOrderResult:
        self.received_items_json = items_json
        self.received_request_hash = request_hash

        return RegisterOrderResult(
            order_id=99,
            order_number="ORD-TEST-000099",
            total_amount=Decimal("4600.00"),
            is_replay=False,
        )


def build_user() -> AuthUser:
    return AuthUser(
        user_id=1,
        username="operador",
        display_name="Operador Demo",
        password_hash="unused",
        is_active=True,
    )


def test_create_order_sorts_items_before_hashing() -> None:
    repository = FakeOrderRepository()
    service = OrderService(repository)

    result = service.create_order(
        current_user=build_user(),
        idempotency_key=UUID("11111111-1111-1111-1111-111111111111"),
        items=[
            OrderItemInput(
                product_id=2,
                quantity=1,
            ),
            OrderItemInput(
                product_id=1,
                quantity=3,
            ),
        ],
    )

    assert result.order_id == 99

    assert repository.received_items_json == (
        '[{"product_id":1,"quantity":3},{"product_id":2,"quantity":1}]'
    )

    assert repository.received_request_hash is not None
    assert len(repository.received_request_hash) == 64


def test_create_order_same_items_different_order_same_hash() -> None:
    repository_a = FakeOrderRepository()
    repository_b = FakeOrderRepository()

    service_a = OrderService(repository_a)
    service_b = OrderService(repository_b)

    key = UUID("22222222-2222-2222-2222-222222222222")

    service_a.create_order(
        current_user=build_user(),
        idempotency_key=key,
        items=[
            OrderItemInput(
                product_id=1,
                quantity=3,
            ),
            OrderItemInput(
                product_id=2,
                quantity=1,
            ),
        ],
    )

    service_b.create_order(
        current_user=build_user(),
        idempotency_key=key,
        items=[
            OrderItemInput(
                product_id=2,
                quantity=1,
            ),
            OrderItemInput(
                product_id=1,
                quantity=3,
            ),
        ],
    )

    assert repository_a.received_request_hash == repository_b.received_request_hash


def test_create_order_rejects_duplicate_products() -> None:
    repository = FakeOrderRepository()
    service = OrderService(repository)

    with pytest.raises(DuplicateProductError):
        service.create_order(
            current_user=build_user(),
            idempotency_key=UUID("33333333-3333-3333-3333-333333333333"),
            items=[
                OrderItemInput(
                    product_id=1,
                    quantity=1,
                ),
                OrderItemInput(
                    product_id=1,
                    quantity=2,
                ),
            ],
        )
