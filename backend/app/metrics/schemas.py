from datetime import date
from decimal import Decimal

from pydantic import BaseModel


class DailyOrderStatusSummaryResponse(BaseModel):
    status: str
    total_orders: int
    total_units: int
    total_amount: Decimal


class DailyCustomerOrderSummaryResponse(BaseModel):
    customer_id: int
    customer_code: str
    customer_name: str
    total_orders: int
    total_units: int
    total_amount: Decimal


class DailyOrderSummaryResponse(BaseModel):
    summary_date: date
    total_orders: int
    confirmed_orders: int
    cancelled_orders: int
    total_units: int
    total_amount: Decimal
    average_order_amount: Decimal
    by_status: list[DailyOrderStatusSummaryResponse]
    by_customer: list[DailyCustomerOrderSummaryResponse]
