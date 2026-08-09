import 'package:equatable/equatable.dart';

import '../../data/order_repository.dart';

enum OrderDetailStatus { initial, loading, success, failure }

class OrderDetailState extends Equatable {
  const OrderDetailState({
    this.status = OrderDetailStatus.initial,
    this.order,
    this.message,
    this.sessionExpired = false,
  });

  final OrderDetailStatus status;
  final OrderDetailModel? order;
  final String? message;
  final bool sessionExpired;

  OrderDetailState copyWith({
    OrderDetailStatus? status,
    OrderDetailModel? order,
    String? message,
    bool sessionExpired = false,
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      message: message,
      sessionExpired: sessionExpired,
    );
  }

  @override
  List<Object?> get props => [status, order, message, sessionExpired];
}
