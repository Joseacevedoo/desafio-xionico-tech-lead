from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal


@dataclass(frozen=True, slots=True)
class OrderSummary:
    order_id: int
    order_number: str
    status: str
    currency_code: str
    total_amount: Decimal
    created_at: datetime
    customer_id: int
    customer_code: str
    customer_name: str
    total_units: int


@dataclass(frozen=True, slots=True)
class OrderListResult:
    items: list[OrderSummary]
    page: int
    page_size: int
    total_items: int
    total_pages: int


@dataclass(frozen=True, slots=True)
class OrderItemInput:
    product_id: int
    quantity: int


@dataclass(frozen=True, slots=True)
class RegisterOrderResult:
    order_id: int
    order_number: str
    total_amount: Decimal
    is_replay: bool


@dataclass(frozen=True, slots=True)
class OrderDetailItem:
    product_id: int
    product_code: str
    product_name: str
    quantity: int
    unit_price: Decimal
    subtotal: Decimal


@dataclass(frozen=True, slots=True)
class OrderDetail:
    order_id: int
    order_number: str
    status: str
    currency_code: str
    total_amount: Decimal
    created_at: datetime

    customer_id: int
    customer_code: str
    customer_name: str

    created_by_user_id: int
    created_by_username: str
    created_by_display_name: str

    items: list[OrderDetailItem]
