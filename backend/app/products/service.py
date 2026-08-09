from dataclasses import dataclass
from math import ceil

from app.products.models import Product
from app.products.repository import ProductRepository


@dataclass(frozen=True, slots=True)
class ProductListResult:
    items: list[Product]
    page: int
    page_size: int
    total_items: int
    total_pages: int


class ProductService:
    """Caso de uso para consultar el catálogo paginado."""

    def __init__(self, repository: ProductRepository) -> None:
        self._repository = repository

    def list_products(
        self,
        *,
        page: int,
        page_size: int,
        search: str | None,
    ) -> ProductListResult:
        normalized_search = self._normalize_search(search)
        offset = (page - 1) * page_size

        total_items = self._repository.count_active_products(
            search=normalized_search,
        )

        items = self._repository.list_active_products(
            search=normalized_search,
            offset=offset,
            page_size=page_size,
        )

        total_pages = ceil(total_items / page_size) if total_items > 0 else 0

        return ProductListResult(
            items=items,
            page=page,
            page_size=page_size,
            total_items=total_items,
            total_pages=total_pages,
        )

    @staticmethod
    def _normalize_search(
        search: str | None,
    ) -> str | None:
        if search is None:
            return None

        normalized = search.strip()

        return normalized if normalized else None
