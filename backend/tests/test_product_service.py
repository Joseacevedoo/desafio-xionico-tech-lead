from decimal import Decimal

from app.products.models import Product
from app.products.service import ProductService


class FakeProductRepository:
    def __init__(self) -> None:
        self.received_search: str | None = "not-called"

    def count_active_products(
        self,
        *,
        search: str | None,
    ) -> int:
        self.received_search = search
        return 9

    def list_active_products(
        self,
        *,
        search: str | None,
        offset: int,
        page_size: int,
    ) -> list[Product]:
        return [
            Product(
                product_id=1,
                code="PROD-001",
                name="Arroz",
                description=None,
                unit_price=Decimal("1850.00"),
                available_stock=25,
            )
        ]


def test_list_products_normalizes_empty_search() -> None:
    repository = FakeProductRepository()
    service = ProductService(repository)

    service.list_products(
        page=1,
        page_size=20,
        search="   ",
    )

    assert repository.received_search is None


def test_list_products_returns_pagination_metadata() -> None:
    repository = FakeProductRepository()
    service = ProductService(repository)

    result = service.list_products(
        page=1,
        page_size=20,
        search="   ",
    )

    assert result.total_items == 9
