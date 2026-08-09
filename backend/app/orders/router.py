from typing import Annotated
from uuid import UUID

from fastapi import (
    APIRouter,
    Depends,
    Header,
    Path,
    Query,
    Response,
    status,
)
from sqlalchemy.orm import Session

from app.auth.dependencies import CurrentUser
from app.core.database import get_db
from app.orders.models import OrderItemInput
from app.orders.repository import OrderRepository
from app.orders.schemas import (
    CreateOrderRequest,
    CreateOrderResponse,
    OrderCreatedByResponse,
    OrderCustomerResponse,
    OrderDetailItemResponse,
    OrderDetailResponse,
    OrderListItemResponse,
    OrderListResponse,
    OrderPaginationResponse,
)
from app.orders.service import OrderService

router = APIRouter(
    prefix="/api/v1/pedidos",
    tags=["Pedidos"],
)

DatabaseSession = Annotated[Session, Depends(get_db)]

IdempotencyKey = Annotated[
    UUID,
    Header(
        alias="X-Idempotency-Key",
        description=(
            "UUID único que identifica el intento lógico de creación del pedido."
        ),
    ),
]
OrderId = Annotated[
    int,
    Path(
        gt=0,
        description="Identificador interno del pedido.",
    ),
]


@router.get(
    "",
    response_model=OrderListResponse,
    summary="Consultar historial de pedidos",
)
def list_orders(
    current_user: CurrentUser,
    db: DatabaseSession,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
) -> OrderListResponse:
    del current_user

    repository = OrderRepository(db)
    service = OrderService(repository)

    result = service.list_orders(
        page=page,
        page_size=page_size,
    )

    return OrderListResponse(
        items=[
            OrderListItemResponse(
                id=order.order_id,
                order_number=order.order_number,
                status=order.status,
                currency_code=order.currency_code,
                total_amount=order.total_amount,
                created_at=order.created_at,
                total_units=order.total_units,
                customer=OrderCustomerResponse(
                    id=order.customer_id,
                    code=order.customer_code,
                    name=order.customer_name,
                ),
            )
            for order in result.items
        ],
        pagination=OrderPaginationResponse(
            page=result.page,
            page_size=result.page_size,
            total_items=result.total_items,
            total_pages=result.total_pages,
        ),
    )


@router.post(
    "",
    response_model=CreateOrderResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar un pedido",
)
def create_order(
    request: CreateOrderRequest,
    response: Response,
    current_user: CurrentUser,
    db: DatabaseSession,
    idempotency_key: IdempotencyKey,
) -> CreateOrderResponse:
    repository = OrderRepository(db)
    service = OrderService(repository)

    result = service.create_order(
        current_user=current_user,
        idempotency_key=idempotency_key,
        items=[
            OrderItemInput(
                product_id=item.product_id,
                quantity=item.quantity,
            )
            for item in request.items
        ],
    )

    if result.is_replay:
        response.status_code = status.HTTP_200_OK
        response.headers["X-Idempotent-Replay"] = "true"
    else:
        response.status_code = status.HTTP_201_CREATED
        response.headers["X-Idempotent-Replay"] = "false"

    return CreateOrderResponse(
        id=result.order_id,
        order_number=result.order_number,
        status="CONFIRMED",
        total_amount=result.total_amount,
        is_replay=result.is_replay,
    )


@router.get(
    "/{order_id}",
    response_model=OrderDetailResponse,
    summary="Consultar detalle de un pedido",
)
def get_order(
    order_id: OrderId,
    current_user: CurrentUser,
    db: DatabaseSession,
) -> OrderDetailResponse:
    del current_user

    repository = OrderRepository(db)
    service = OrderService(repository)

    order = service.get_order(
        order_id=order_id,
    )

    return OrderDetailResponse(
        id=order.order_id,
        order_number=order.order_number,
        status=order.status,
        currency_code=order.currency_code,
        total_amount=order.total_amount,
        created_at=order.created_at,
        customer=OrderCustomerResponse(
            id=order.customer_id,
            code=order.customer_code,
            name=order.customer_name,
        ),
        created_by=OrderCreatedByResponse(
            id=order.created_by_user_id,
            username=order.created_by_username,
            display_name=order.created_by_display_name,
        ),
        items=[
            OrderDetailItemResponse(
                product_id=item.product_id,
                product_code=item.product_code,
                product_name=item.product_name,
                quantity=item.quantity,
                unit_price=item.unit_price,
                subtotal=item.subtotal,
            )
            for item in order.items
        ],
    )
