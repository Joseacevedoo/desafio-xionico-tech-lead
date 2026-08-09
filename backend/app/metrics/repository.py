from datetime import date
from decimal import Decimal

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.metrics.models import (
    DailyCustomerOrderSummary,
    DailyOrderStatusSummary,
    DailyOrderSummary,
)


class MetricsRepository:
    """Acceso a métricas operativas desde SQL Server."""

    def __init__(self, db: Session) -> None:
        self._db = db

    def get_daily_order_summary(
        self,
        *,
        summary_date: date,
    ) -> DailyOrderSummary:
        totals_statement = text(
            """
            SELECT
                summary_date,
                COALESCE(SUM(total_orders), 0) AS total_orders,
                COALESCE(SUM(CASE WHEN status = N'CONFIRMED' THEN total_orders ELSE 0 END), 0)
                    AS confirmed_orders,
                COALESCE(SUM(CASE WHEN status = N'CANCELLED' THEN total_orders ELSE 0 END), 0)
                    AS cancelled_orders,
                COALESCE(SUM(total_units), 0) AS total_units,
                COALESCE(SUM(total_amount), 0) AS total_amount,
                CASE
                    WHEN COALESCE(SUM(total_orders), 0) = 0 THEN 0
                    ELSE COALESCE(SUM(total_amount), 0) / SUM(total_orders)
                END AS average_order_amount
            FROM dbo.vw_DailyOrderSummary
            WHERE summary_date = :summary_date
            GROUP BY summary_date;
            """
        )

        totals = (
            self._db.execute(
                totals_statement,
                {"summary_date": summary_date},
            )
            .mappings()
            .first()
        )

        if totals is None:
            return DailyOrderSummary(
                summary_date=summary_date,
                total_orders=0,
                confirmed_orders=0,
                cancelled_orders=0,
                total_units=0,
                total_amount=Decimal("0.00"),
                average_order_amount=Decimal("0.00"),
                by_status=[],
                by_customer=[],
            )

        by_status = self._get_daily_summary_by_status(
            summary_date=summary_date,
        )
        by_customer = self._get_daily_summary_by_customer(
            summary_date=summary_date,
        )

        return DailyOrderSummary(
            summary_date=totals["summary_date"],
            total_orders=int(totals["total_orders"]),
            confirmed_orders=int(totals["confirmed_orders"]),
            cancelled_orders=int(totals["cancelled_orders"]),
            total_units=int(totals["total_units"]),
            total_amount=totals["total_amount"],
            average_order_amount=totals["average_order_amount"],
            by_status=by_status,
            by_customer=by_customer,
        )

    def _get_daily_summary_by_status(
        self,
        *,
        summary_date: date,
    ) -> list[DailyOrderStatusSummary]:
        statement = text(
            """
            SELECT
                status,
                SUM(total_orders) AS total_orders,
                SUM(total_units) AS total_units,
                SUM(total_amount) AS total_amount
            FROM dbo.vw_DailyOrderSummary
            WHERE summary_date = :summary_date
            GROUP BY status
            ORDER BY status ASC;
            """
        )

        rows = (
            self._db.execute(
                statement,
                {"summary_date": summary_date},
            )
            .mappings()
            .all()
        )

        return [
            DailyOrderStatusSummary(
                status=row["status"],
                total_orders=int(row["total_orders"]),
                total_units=int(row["total_units"]),
                total_amount=row["total_amount"],
            )
            for row in rows
        ]

    def _get_daily_summary_by_customer(
        self,
        *,
        summary_date: date,
    ) -> list[DailyCustomerOrderSummary]:
        statement = text(
            """
            SELECT
                customer_id,
                customer_code,
                customer_name,
                SUM(total_orders) AS total_orders,
                SUM(total_units) AS total_units,
                SUM(total_amount) AS total_amount
            FROM dbo.vw_DailyOrderSummary
            WHERE summary_date = :summary_date
            GROUP BY
                customer_id,
                customer_code,
                customer_name
            ORDER BY total_amount DESC, customer_name ASC;
            """
        )

        rows = (
            self._db.execute(
                statement,
                {"summary_date": summary_date},
            )
            .mappings()
            .all()
        )

        return [
            DailyCustomerOrderSummary(
                customer_id=int(row["customer_id"]),
                customer_code=row["customer_code"],
                customer_name=row["customer_name"],
                total_orders=int(row["total_orders"]),
                total_units=int(row["total_units"]),
                total_amount=row["total_amount"],
            )
            for row in rows
        ]
