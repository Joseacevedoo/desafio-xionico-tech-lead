import 'package:equatable/equatable.dart';

import '../../data/order_draft_item.dart';

enum OrderStatus { initial, submitting, success, failure }

class OrderState extends Equatable {
  const OrderState({
    this.status = OrderStatus.initial,
    this.items = const [],
    this.orderId,
    this.orderNumber,
    this.totalAmount,
    this.message,
    this.sessionExpired = false,
  });

  final OrderStatus status;
  final List<OrderDraftItem> items;
  final int? orderId;
  final String? orderNumber;
  final double? totalAmount;
  final String? message;
  final bool sessionExpired;

  int get totalQuantity {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  double get estimatedTotal {
    return items.fold(0, (total, item) => total + item.subtotal);
  }

  OrderState copyWith({
    OrderStatus? status,
    List<OrderDraftItem>? items,
    int? orderId,
    String? orderNumber,
    double? totalAmount,
    String? message,
    bool sessionExpired = false,
  }) {
    return OrderState(
      status: status ?? this.status,
      items: items ?? this.items,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      message: message,
      sessionExpired: sessionExpired,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    orderId,
    orderNumber,
    totalAmount,
    message,
    sessionExpired,
  ];
}
