from sqlalchemy import text
from sqlalchemy.orm import Session

from app.products.models import Product


class ProductRepository:
    """Acceso a productos e inventario desde SQL Server."""

    def __init__(self, db: Session) -> None:
        self._db = db

    def count_active_products(
        self,
        *,
        search: str | None,
    ) -> int:
        statement = text(
            """
            SELECT COUNT_BIG(*) AS total_items
            FROM dbo.products AS p
            INNER JOIN dbo.inventory AS i
                ON i.product_id = p.product_id
            WHERE p.is_active = 1
              AND (
                    :search IS NULL
                    OR p.code LIKE '%' + :search + '%'
                    OR p.name LIKE '%' + :search + '%'
              );
            """
        )

        result = self._db.execute(
            statement,
            {"search": search},
        ).scalar_one()

        return int(result)

    def list_active_products(
        self,
        *,
        search: str | None,
        offset: int,
        page_size: int,
    ) -> list[Product]:
        statement = text(
            """
            SELECT
                p.product_id,
                p.code,
                p.name,
                p.description,
                p.unit_price,
                i.available_stock
            FROM dbo.products AS p
            INNER JOIN dbo.inventory AS i
                ON i.product_id = p.product_id
            WHERE p.is_active = 1
              AND (
                    :search IS NULL
                    OR p.code LIKE '%' + :search + '%'
                    OR p.name LIKE '%' + :search + '%'
              )
            ORDER BY p.product_id ASC
            OFFSET :offset ROWS
            FETCH NEXT :page_size ROWS ONLY;
            """
        )

        rows = (
            self._db.execute(
                statement,
                {
                    "search": search,
                    "offset": offset,
                    "page_size": page_size,
                },
            )
            .mappings()
            .all()
        )

        return [
            Product(
                product_id=row["product_id"],
                code=row["code"],
                name=row["name"],
                description=row["description"],
                unit_price=row["unit_price"],
                available_stock=row["available_stock"],
            )
            for row in rows
        ]
