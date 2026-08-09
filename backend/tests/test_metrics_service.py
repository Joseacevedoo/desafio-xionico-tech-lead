from datetime import date
from decimal import Decimal

from app.metrics.models import (
    DailyCustomerOrderSummary,
    DailyOrderStatusSummary,
    DailyOrderSummary,
)
from app.metrics.service import MetricsService


class FakeMetricsRepository:
    def __init__(self) -> None:
        self.received_summary_date: date | None = None

    def get_daily_order_summary(
        self,
        *,
        summary_date: date,
    ) -> DailyOrderSummary:
        self.received_summary_date = summary_date

        return DailyOrderSummary(
            summary_date=summary_date,
            total_orders=2,
            confirmed_orders=2,
            cancelled_orders=0,
            total_units=5,
            total_amount=Decimal("6450.00"),
            average_order_amount=Decimal("3225.00"),
            by_status=[
                DailyOrderStatusSummary(
                    status="CONFIRMED",
                    total_orders=2,
                    total_units=5,
                    total_amount=Decimal("6450.00"),
                )
            ],
            by_customer=[
                DailyCustomerOrderSummary(
                    customer_id=1,
                    customer_code="CUST-DEFAULT",
                    customer_name="Cliente Demo",
                    total_orders=2,
                    total_units=5,
                    total_amount=Decimal("6450.00"),
                )
            ],
        )


def test_get_daily_summary_uses_requested_date() -> None:
    repository = FakeMetricsRepository()
    service = MetricsService(repository)
    requested_date = date(2026, 8, 9)

    result = service.get_daily_summary(
        summary_date=requested_date,
    )

    assert repository.received_summary_date == requested_date
    assert result.total_orders == 2
    assert result.total_units == 5
    assert result.by_status[0].status == "CONFIRMED"
    assert result.by_customer[0].customer_code == "CUST-DEFAULT"
