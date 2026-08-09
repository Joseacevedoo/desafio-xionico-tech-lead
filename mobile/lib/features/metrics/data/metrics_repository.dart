import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'daily_metrics_model.dart';

class MetricsRepository {
  MetricsRepository(this._dio);

  final Dio _dio;

  Future<DailyMetricsModel> getDailySummary() async {
    try {
      final response = await _dio.get('/api/v1/metricas/resumen-diario');
      final data = response.data as Map<String, dynamic>;

      return DailyMetricsModel.fromJson(data);
    } on DioException catch (error) {
      final response = error.response;

      if (response?.data is Map<String, dynamic>) {
        final data = response!.data as Map<String, dynamic>;

        throw ApiException(
          code: data['code']?.toString() ?? 'API_ERROR',
          message:
              data['message']?.toString() ??
              'No fue posible obtener las métricas.',
          statusCode: response.statusCode,
          details: data['details'],
        );
      }

      throw ApiException(
        code: 'NETWORK_ERROR',
        message: 'No fue posible comunicarse con el servidor.',
        statusCode: response?.statusCode,
      );
    }
  }
}
