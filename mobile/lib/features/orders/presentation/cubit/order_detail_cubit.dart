import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/order_repository.dart';
import 'order_detail_state.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  OrderDetailCubit(this._repository) : super(const OrderDetailState());

  final OrderRepository _repository;

  Future<void> loadOrder(int orderId) async {
    emit(state.copyWith(status: OrderDetailStatus.loading, message: null));

    try {
      final order = await _repository.getOrderById(orderId);

      emit(
        state.copyWith(
          status: OrderDetailStatus.success,
          order: order,
          message: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: OrderDetailStatus.failure,
          message: error.isSessionExpired
              ? 'La sesión ha expirado.'
              : error.message,
          sessionExpired: error.isSessionExpired,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: OrderDetailStatus.failure,
          message: 'Ocurrió un error inesperado.',
        ),
      );
    }
  }
}
