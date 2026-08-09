import 'package:equatable/equatable.dart';

import '../../data/order_repository.dart';

enum OrderHistoryStatus { initial, loading, success, failure }

class OrderHistoryState extends Equatable {
  const OrderHistoryState({
    this.status = OrderHistoryStatus.initial,
    this.items = const [],
    this.page = 1,
    this.pageSize = 20,
    this.totalItems = 0,
    this.totalPages = 0,
    this.message,
    this.sessionExpired = false,
  });

  final OrderHistoryStatus status;
  final List<OrderListItemModel> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final String? message;
  final bool sessionExpired;

  OrderHistoryState copyWith({
    OrderHistoryStatus? status,
    List<OrderListItemModel>? items,
    int? page,
    int? pageSize,
    int? totalItems,
    int? totalPages,
    String? message,
    bool sessionExpired = false,
  }) {
    return OrderHistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
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
    message,
    sessionExpired,
  ];
}
