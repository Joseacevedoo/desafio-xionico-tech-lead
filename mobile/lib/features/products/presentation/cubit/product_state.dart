import 'package:equatable/equatable.dart';

import '../../data/product_model.dart';

enum ProductStatus { initial, loading, success, failure }

class ProductState extends Equatable {
  const ProductState({
    this.status = ProductStatus.initial,
    this.items = const [],
    this.page = 1,
    this.pageSize = 20,
    this.totalItems = 0,
    this.totalPages = 0,
    this.search = '',
    this.message,
    this.sessionExpired = false,
  });

  final ProductStatus status;
  final List<ProductModel> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final String search;
  final String? message;
  final bool sessionExpired;

  ProductState copyWith({
    ProductStatus? status,
    List<ProductModel>? items,
    int? page,
    int? pageSize,
    int? totalItems,
    int? totalPages,
    String? search,
    String? message,
    bool sessionExpired = false,
  }) {
    return ProductState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      search: search ?? this.search,
      message: message,
      sessionExpired: sessionExpired,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    page,
    pageSize,
    totalItems,
    totalPages,
    search,
    message,
    sessionExpired,
  ];
}
