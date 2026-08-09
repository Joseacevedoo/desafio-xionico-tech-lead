from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.auth.dependencies import CurrentUser
from app.core.database import get_db
from app.products.repository import ProductRepository
from app.products.schemas import (
    PaginationResponse,
    ProductListResponse,
    ProductResponse,
)
from app.products.service import ProductService

router = APIRouter(
    prefix="/api/v1/productos",
    tags=["Productos"],
)

DatabaseSession = Annotated[Session, Depends(get_db)]


@router.get(
    "",
    response_model=ProductListResponse,
    summary="Consultar catálogo de productos",
)
def list_products(
    current_user: CurrentUser,
    db: DatabaseSession,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
    search: Annotated[
        str | None,
        Query(max_length=100),
    ] = None,
) -> ProductListResponse:
    del current_user

    repository = ProductRepository(db)
    service = ProductService(repository)

    result = service.list_products(
        page=page,
        page_size=page_size,
        search=search,
    )

    return ProductListResponse(
        items=[
            ProductResponse(
                id=product.product_id,
                code=product.code,
                name=product.name,
                description=product.description,
                unit_price=product.unit_price,
                available_stock=product.available_stock,
            )
            for product in result.items
        ],
        pagination=PaginationResponse(
            page=result.page,
            page_size=result.page_size,
            total_items=result.total_items,
            total_pages=result.total_pages,
        ),
    )
