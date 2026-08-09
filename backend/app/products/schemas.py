from decimal import Decimal

from pydantic import BaseModel, Field


class ProductResponse(BaseModel):
    id: int
    code: str
    name: str
    description: str | None
    unit_price: Decimal
    available_stock: int


class PaginationResponse(BaseModel):
    page: int
    page_size: int
    total_items: int
    total_pages: int


class ProductListResponse(BaseModel):
    items: list[ProductResponse]
    pagination: PaginationResponse


class ProductQueryParams(BaseModel):
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
    search: str | None = Field(
        default=None,
        max_length=100,
    )
