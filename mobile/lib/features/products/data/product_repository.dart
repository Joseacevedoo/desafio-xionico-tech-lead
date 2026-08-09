import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'product_model.dart';

class ProductListResult {
  const ProductListResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  final List<ProductModel> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
}

class ProductRepository {
  ProductRepository(this._dio);

  final Dio _dio;

  Future<ProductListResult> getProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/productos',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );

      final data = response.data as Map<String, dynamic>;

      final rawItems = data['items'] as List<dynamic>;
      final pagination = data['pagination'] as Map<String, dynamic>;

      return ProductListResult(
        items: rawItems
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList(),
        page: pagination['page'] as int,
        pageSize: pagination['page_size'] as int,
        totalItems: pagination['total_items'] as int,
        totalPages: pagination['total_pages'] as int,
      );
    } on DioException catch (error) {
      final response = error.response;

      if (response?.data is Map<String, dynamic>) {
        final data = response!.data as Map<String, dynamic>;

        throw ApiException(
          code: data['code']?.toString() ?? 'API_ERROR',
          message:
              data['message']?.toString() ??
              'No fue posible obtener los productos.',
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
