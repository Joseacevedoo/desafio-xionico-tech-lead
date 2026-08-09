import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/order_repository.dart';
import 'order_history_state.dart';

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  OrderHistoryCubit(this._repository) : super(const OrderHistoryState());

  final OrderRepository _repository;

  Future<void> loadOrders({int page = 1}) async {
    emit(state.copyWith(status: OrderHistoryStatus.loading, message: null));

    try {
      final result = await _repository.getOrders(
        page: page,
        pageSize: state.pageSize,
      );

      emit(
        state.copyWith(
          status: OrderHistoryStatus.success,
          items: result.items,
          page: result.page,
          pageSize: result.pageSize,
          totalItems: result.totalItems,
          totalPages: result.totalPages,
          message: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: OrderHistoryStatus.failure,
          message: error.isSessionExpired
              ? 'La sesión ha expirado.'
              : error.message,
          sessionExpired: error.isSessionExpired,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: OrderHistoryStatus.failure,
          message: 'Ocurrió un error inesperado.',
        ),
      );
    }
  }

  Future<void> nextPage() async {
    if (state.page >= state.totalPages) {
      return;
    }

    await loadOrders(page: state.page + 1);
  }

  Future<void> previousPage() async {
    if (state.page <= 1) {
      return;
    }

    await loadOrders(page: state.page - 1);
  }
}
