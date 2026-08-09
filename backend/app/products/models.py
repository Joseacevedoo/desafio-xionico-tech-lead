from dataclasses import dataclass
from decimal import Decimal


@dataclass(frozen=True, slots=True)
class Product:
    """Producto activo junto con su disponibilidad actual."""

    product_id: int
    code: str
    name: str
    description: str | None
    unit_price: Decimal
    available_stock: int
