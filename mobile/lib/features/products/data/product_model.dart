class ProductModel {
  const ProductModel({
    required this.id,
    required this.code,
    required this.name,
    required this.unitPrice,
    required this.availableStock,
    this.description,
  });

  final int id;
  final String code;
  final String name;
  final String? description;
  final double unitPrice;
  final int availableStock;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      unitPrice: double.parse(json['unit_price'].toString()),
      availableStock: json['available_stock'] as int,
    );
  }
}
