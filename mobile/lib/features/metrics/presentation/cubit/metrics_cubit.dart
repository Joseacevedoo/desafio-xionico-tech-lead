import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/metrics_repository.dart';
import 'metrics_state.dart';

class MetricsCubit extends Cubit<MetricsState> {
  MetricsCubit(this._repository) : super(const MetricsState());

  final MetricsRepository _repository;

  Future<void> loadSummary() async {
    emit(state.copyWith(status: MetricsStatus.loading, message: null));

    try {
      final summary = await _repository.getDailySummary();

      emit(
        state.copyWith(
          status: MetricsStatus.success,
          summary: summary,
          message: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: MetricsStatus.failure,
          message: error.isSessionExpired
              ? 'La sesión ha expirado.'
              : error.message,
          sessionExpired: error.isSessionExpired,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: MetricsStatus.failure,
          message: 'Ocurrió un error inesperado.',
        ),
      );
    }
  }
}
