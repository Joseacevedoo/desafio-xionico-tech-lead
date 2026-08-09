from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field, model_validator

from app.core.config import get_settings

settings = get_settings()


class OrderItemCreate(BaseModel):
    product_id: int = Field(
        gt=0,
        examples=[1],
    )
    quantity: int = Field(
        gt=0,
        le=settings.max_item_quantity,
        examples=[2],
    )


class CreateOrderRequest(BaseModel):
    items: list[OrderItemCreate] = Field(
        min_length=1,
        max_length=settings.max_order_items,
    )

    @model_validator(mode="after")
    def validate_unique_products(self) -> "CreateOrderRequest":
        product_ids = [item.product_id for item in self.items]

        if len(product_ids) != len(set(product_ids)):
            raise ValueError("Cada producto puede aparecer una sola vez.")

        return self


class CreateOrderResponse(BaseModel):
    id: int
    order_number: str
    status: str
    total_amount: Decimal
    is_replay: bool


class OrderPaginationResponse(BaseModel):
    page: int
    page_size: int
    total_items: int
    total_pages: int


class OrderCustomerResponse(BaseModel):
    id: int
    code: str
    name: str


class OrderCreatedByResponse(BaseModel):
    id: int
    username: str
    display_name: str


class OrderDetailItemResponse(BaseModel):
    product_id: int
    product_code: str
    product_name: str
    quantity: int
    unit_price: Decimal
    subtotal: Decimal


class OrderDetailResponse(BaseModel):
    id: int
    order_number: str
    status: str
    currency_code: str
    total_amount: Decimal
    created_at: datetime

    customer: OrderCustomerResponse
    created_by: OrderCreatedByResponse
    items: list[OrderDetailItemResponse]


class OrderListItemResponse(BaseModel):
    id: int
    order_number: str
    status: str
    currency_code: str
    total_amount: Decimal
    created_at: datetime
    total_units: int
    customer: OrderCustomerResponse


class OrderListResponse(BaseModel):
    items: list[OrderListItemResponse]
    pagination: OrderPaginationResponse
