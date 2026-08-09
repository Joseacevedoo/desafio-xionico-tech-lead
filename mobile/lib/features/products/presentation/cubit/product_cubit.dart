import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/product_repository.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  ProductCubit(this._repository) : super(const ProductState());

  final ProductRepository _repository;

  Future<void> loadProducts({int page = 1, String? search}) async {
    emit(state.copyWith(status: ProductStatus.loading, message: null));

    try {
      final result = await _repository.getProducts(
        page: page,
        pageSize: state.pageSize,
        search: search,
      );

      emit(
        state.copyWith(
          status: ProductStatus.success,
          items: result.items,
          page: result.page,
          pageSize: result.pageSize,
          totalItems: result.totalItems,
          totalPages: result.totalPages,
          search: search ?? '',
          message: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: ProductStatus.failure,
          message: error.isSessionExpired
              ? 'La sesión ha expirado.'
              : error.message,
          sessionExpired: error.isSessionExpired,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProductStatus.failure,
          message: 'Ocurrió un error inesperado.',
        ),
      );
    }
  }

  Future<void> nextPage() async {
    if (state.page >= state.totalPages) {
      return;
    }

    await loadProducts(page: state.page + 1, search: state.search);
  }

  Future<void> previousPage() async {
    if (state.page <= 1) {
      return;
    }

    await loadProducts(page: state.page - 1, search: state.search);
  }
}
