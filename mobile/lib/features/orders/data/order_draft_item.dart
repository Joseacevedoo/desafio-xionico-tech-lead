import '../../products/data/product_model.dart';

class OrderDraftItem {
  const OrderDraftItem({required this.product, required this.quantity});

  final ProductModel product;
  final int quantity;

  double get subtotal => product.unitPrice * quantity;

  OrderDraftItem copyWith({ProductModel? product, int? quantity}) {
    return OrderDraftItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
