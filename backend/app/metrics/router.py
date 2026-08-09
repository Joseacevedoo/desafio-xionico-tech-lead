from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.auth.dependencies import CurrentUser
from app.core.database import get_db
from app.metrics.repository import MetricsRepository
from app.metrics.schemas import (
    DailyCustomerOrderSummaryResponse,
    DailyOrderStatusSummaryResponse,
    DailyOrderSummaryResponse,
)
from app.metrics.service import MetricsService

router = APIRouter(
    prefix="/api/v1/metricas",
    tags=["Métricas"],
)

DatabaseSession = Annotated[Session, Depends(get_db)]


@router.get(
    "/resumen-diario",
    response_model=DailyOrderSummaryResponse,
    summary="Consultar métricas operativas diarias",
)
def get_daily_order_summary(
    current_user: CurrentUser,
    db: DatabaseSession,
    summary_date: Annotated[
        date | None,
        Query(
            description=(
                "Fecha operativa en formato YYYY-MM-DD. "
                "Si no se informa, se usa la fecha UTC actual."
            ),
        ),
    ] = None,
) -> DailyOrderSummaryResponse:
    del current_user

    repository = MetricsRepository(db)
    service = MetricsService(repository)

    summary = (
        service.get_daily_summary(summary_date=summary_date)
        if summary_date is not None
        else service.get_today_summary()
    )

    return DailyOrderSummaryResponse(
        summary_date=summary.summary_date,
        total_orders=summary.total_orders,
        confirmed_orders=summary.confirmed_orders,
        cancelled_orders=summary.cancelled_orders,
        total_units=summary.total_units,
        total_amount=summary.total_amount,
        average_order_amount=summary.average_order_amount,
        by_status=[
            DailyOrderStatusSummaryResponse(
                status=item.status,
                total_orders=item.total_orders,
                total_units=item.total_units,
                total_amount=item.total_amount,
            )
            for item in summary.by_status
        ],
        by_customer=[
            DailyCustomerOrderSummaryResponse(
                customer_id=item.customer_id,
                customer_code=item.customer_code,
                customer_name=item.customer_name,
                total_orders=item.total_orders,
                total_units=item.total_units,
                total_amount=item.total_amount,
            )
            for item in summary.by_customer
        ],
    )
