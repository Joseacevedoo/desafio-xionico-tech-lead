from datetime import date, datetime, timezone

from app.metrics.models import DailyOrderSummary
from app.metrics.repository import MetricsRepository


class MetricsService:
    """Caso de uso para consultar métricas clave de operación."""

    def __init__(self, repository: MetricsRepository) -> None:
        self._repository = repository

    def get_today_summary(self) -> DailyOrderSummary:
        today = datetime.now(timezone.utc).date()

        return self._repository.get_daily_order_summary(
            summary_date=today,
        )

    def get_daily_summary(
        self,
        *,
        summary_date: date,
    ) -> DailyOrderSummary:
        return self._repository.get_daily_order_summary(
            summary_date=summary_date,
        )
