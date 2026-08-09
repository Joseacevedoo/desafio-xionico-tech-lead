import 'package:dio/dio.dart';
import 'package:mobile/features/orders/data/order_draft_item.dart';

import '../../../core/network/api_exception.dart';

class OrderCustomerModel {
  const OrderCustomerModel({
    required this.id,
    required this.code,
    required this.name,
  });

  final int id;
  final String code;
  final String name;

  factory OrderCustomerModel.fromJson(Map<String, dynamic> json) {
    return OrderCustomerModel(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }
}

class OrderListItemModel {
  const OrderListItemModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.currencyCode,
    required this.totalAmount,
    required this.createdAt,
    required this.totalUnits,
    required this.customer,
  });

  final int id;
  final String orderNumber;
  final String status;
  final String currencyCode;
  final double totalAmount;
  final DateTime createdAt;
  final int totalUnits;
  final OrderCustomerModel customer;

  factory OrderListItemModel.fromJson(Map<String, dynamic> json) {
    return OrderListItemModel(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      currencyCode: json['currency_code'] as String,
      totalAmount: double.parse(json['total_amount'].toString()),
      createdAt: DateTime.parse(json['created_at'] as String),
      totalUnits: json['total_units'] as int,
      customer: OrderCustomerModel.fromJson(
        json['customer'] as Map<String, dynamic>,
      ),
    );
  }
}

class OrderListResult {
  const OrderListResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  final List<OrderListItemModel> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
}

class OrderCreatedByModel {
  const OrderCreatedByModel({
    required this.id,
    required this.username,
    required this.displayName,
  });

  final int id;
  final String username;
  final String displayName;

  factory OrderCreatedByModel.fromJson(Map<String, dynamic> json) {
    return OrderCreatedByModel(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
    );
  }
}

class OrderDetailItemModel {
  const OrderDetailItemModel({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final int productId;
  final String productCode;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  factory OrderDetailItemModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailItemModel(
      productId: json['product_id'] as int,
      productCode: json['product_code'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: double.parse(json['unit_price'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}

class OrderDetailModel {
  const OrderDetailModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.currencyCode,
    required this.totalAmount,
    required this.createdAt,
    required this.customer,
    required this.createdBy,
    required this.items,
  });

  final int id;
  final String orderNumber;
  final String status;
  final String currencyCode;
  final double totalAmount;
  final DateTime createdAt;
  final OrderCustomerModel customer;
  final OrderCreatedByModel createdBy;
  final List<OrderDetailItemModel> items;

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      currencyCode: json['currency_code'] as String,
      totalAmount: double.parse(json['total_amount'].toString()),
      createdAt: DateTime.parse(json['created_at'] as String),
      customer: OrderCustomerModel.fromJson(
        json['customer'] as Map<String, dynamic>,
      ),
      createdBy: OrderCreatedByModel.fromJson(
        json['created_by'] as Map<String, dynamic>,
      ),
      items: (json['items'] as List<dynamic>)
          .map(
            (item) =>
                OrderDetailItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class CreateOrderResult {
  const CreateOrderResult({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.isReplay,
  });

  final int id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final bool isReplay;
}

class OrderRepository {
  OrderRepository(this._dio);

  final Dio _dio;

  Future<OrderListResult> getOrders({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get(
        '/api/v1/pedidos',
        queryParameters: {'page': page, 'page_size': pageSize},
      );

      final data = response.data as Map<String, dynamic>;
      final rawItems = data['items'] as List<dynamic>;
      final pagination = data['pagination'] as Map<String, dynamic>;

      return OrderListResult(
        items: rawItems
            .map(
              (item) =>
                  OrderListItemModel.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        page: pagination['page'] as int,
        pageSize: pagination['page_size'] as int,
        totalItems: pagination['total_items'] as int,
        totalPages: pagination['total_pages'] as int,
      );
    } on DioException catch (error) {
      throw _mapDioException(
        error,
        fallbackMessage: 'No fue posible obtener los pedidos.',
      );
    }
  }

  Future<OrderDetailModel> getOrderById(int orderId) async {
    try {
      final response = await _dio.get('/api/v1/pedidos/$orderId');
      final data = response.data as Map<String, dynamic>;

      return OrderDetailModel.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(
        error,
        fallbackMessage: 'No fue posible obtener el detalle del pedido.',
      );
    }
  }

  Future<CreateOrderResult> createOrder({
    required List<OrderDraftItem> items,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/pedidos',
        data: {
          'items': items
              .map(
                (item) => {
                  'product_id': item.product.id,
                  'quantity': item.quantity,
                },
              )
              .toList(),
        },
        options: Options(headers: {'X-Idempotency-Key': idempotencyKey}),
      );

      final data = response.data as Map<String, dynamic>;

      return CreateOrderResult(
        id: data['id'] as int,
        orderNumber: data['order_number'] as String,
        status: data['status'] as String,
        totalAmount: double.parse(data['total_amount'].toString()),
        isReplay: data['is_replay'] as bool,
      );
    } on DioException catch (error) {
      throw _mapDioException(
        error,
        fallbackMessage: 'No fue posible registrar el pedido.',
      );
    }
  }

  ApiException _mapDioException(
    DioException error, {
    required String fallbackMessage,
  }) {
    final response = error.response;

    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;

      return ApiException(
        code: data['code']?.toString() ?? 'API_ERROR',
        message: data['message']?.toString() ?? fallbackMessage,
        statusCode: response.statusCode,
        details: data['details'],
      );
    }

    return ApiException(
      code: 'NETWORK_ERROR',
      message: 'No fue posible comunicarse con el servidor.',
      statusCode: response?.statusCode,
    );
  }
}
