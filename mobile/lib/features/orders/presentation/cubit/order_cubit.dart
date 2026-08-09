import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_exception.dart';
import '../../../products/data/product_model.dart';
import '../../data/order_draft_item.dart';
import '../../data/order_repository.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  OrderCubit(this._repository) : super(const OrderState());

  final OrderRepository _repository;
  final Uuid _uuid = const Uuid();

  String? _idempotencyKey;

  void addProduct(ProductModel product) {
    final items = [...state.items];

    final index = items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      final current = items[index];

      items[index] = current.copyWith(quantity: current.quantity + 1);
    } else {
      items.add(OrderDraftItem(product: product, quantity: 1));
    }

    _invalidateIdempotencyKey();

    emit(
      state.copyWith(status: OrderStatus.initial, items: items, message: null),
    );
  }

  void incrementQuantity(int productId) {
    _updateQuantity(productId: productId, delta: 1);
  }

  void decrementQuantity(int productId) {
    _updateQuantity(productId: productId, delta: -1);
  }

  void removeProduct(int productId) {
    final items = state.items
        .where((item) => item.product.id != productId)
        .toList();

    _invalidateIdempotencyKey();

    emit(
      state.copyWith(status: OrderStatus.initial, items: items, message: null),
    );
  }

  Future<void> submitOrder() async {
    if (state.status == OrderStatus.submitting ||
        state.status == OrderStatus.success) {
      return;
    }

    if (state.items.isEmpty) {
      emit(
        state.copyWith(
          status: OrderStatus.failure,
          message: 'El pedido no contiene productos.',
        ),
      );
      return;
    }

    _idempotencyKey ??= _uuid.v4();

    emit(state.copyWith(status: OrderStatus.submitting, message: null));

    try {
      final result = await _repository.createOrder(
        items: state.items,
        idempotencyKey: _idempotencyKey!,
      );

      emit(
        state.copyWith(
          status: OrderStatus.success,
          orderId: result.id,
          orderNumber: result.orderNumber,
          totalAmount: result.totalAmount,
          message: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: OrderStatus.failure,
          message: error.isSessionExpired
              ? 'La sesión ha expirado.'
              : error.message,
          sessionExpired: error.isSessionExpired,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: OrderStatus.failure,
          message: 'Ocurrió un error inesperado.',
        ),
      );
    }
  }

  void clearOrder() {
    _idempotencyKey = null;

    emit(const OrderState());
  }

  void _updateQuantity({required int productId, required int delta}) {
    final items = [...state.items];

    final index = items.indexWhere((item) => item.product.id == productId);

    if (index < 0) {
      return;
    }

    final item = items[index];
    final newQuantity = item.quantity + delta;

    if (newQuantity <= 0) {
      items.removeAt(index);
    } else {
      items[index] = item.copyWith(quantity: newQuantity);
    }

    _invalidateIdempotencyKey();

    emit(
      state.copyWith(status: OrderStatus.initial, items: items, message: null),
    );
  }

  void _invalidateIdempotencyKey() {
    _idempotencyKey = null;
  }
}
