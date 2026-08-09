from dataclasses import dataclass
from datetime import date
from decimal import Decimal


@dataclass(frozen=True, slots=True)
class DailyOrderStatusSummary:
    status: str
    total_orders: int
    total_units: int
    total_amount: Decimal


@dataclass(frozen=True, slots=True)
class DailyCustomerOrderSummary:
    customer_id: int
    customer_code: str
    customer_name: str
    total_orders: int
    total_units: int
    total_amount: Decimal


@dataclass(frozen=True, slots=True)
class DailyOrderSummary:
    """Resumen operativo diario basado en pedidos registrados."""

    summary_date: date
    total_orders: int
    confirmed_orders: int
    cancelled_orders: int
    total_units: int
    total_amount: Decimal
    average_order_amount: Decimal
    by_status: list[DailyOrderStatusSummary]
    by_customer: list[DailyCustomerOrderSummary]
