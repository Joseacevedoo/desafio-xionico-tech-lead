class DailyMetricsModel {
  const DailyMetricsModel({
    required this.summaryDate,
    required this.totalOrders,
    required this.confirmedOrders,
    required this.cancelledOrders,
    required this.totalUnits,
    required this.totalAmount,
    required this.averageOrderAmount,
    required this.byStatus,
    required this.byCustomer,
  });

  final DateTime summaryDate;
  final int totalOrders;
  final int confirmedOrders;
  final int cancelledOrders;
  final int totalUnits;
  final double totalAmount;
  final double averageOrderAmount;
  final List<DailyStatusMetricsModel> byStatus;
  final List<DailyCustomerMetricsModel> byCustomer;

  factory DailyMetricsModel.fromJson(Map<String, dynamic> json) {
    return DailyMetricsModel(
      summaryDate: DateTime.parse(json['summary_date'] as String),
      totalOrders: json['total_orders'] as int,
      confirmedOrders: json['confirmed_orders'] as int,
      cancelledOrders: json['cancelled_orders'] as int,
      totalUnits: json['total_units'] as int,
      totalAmount: double.parse(json['total_amount'].toString()),
      averageOrderAmount: double.parse(json['average_order_amount'].toString()),
      byStatus: (json['by_status'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                DailyStatusMetricsModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      byCustomer: (json['by_customer'] as List<dynamic>? ?? [])
          .map(
            (item) => DailyCustomerMetricsModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class DailyStatusMetricsModel {
  const DailyStatusMetricsModel({
    required this.status,
    required this.totalOrders,
    required this.totalUnits,
    required this.totalAmount,
  });

  final String status;
  final int totalOrders;
  final int totalUnits;
  final double totalAmount;

  factory DailyStatusMetricsModel.fromJson(Map<String, dynamic> json) {
    return DailyStatusMetricsModel(
      status: json['status'] as String,
      totalOrders: json['total_orders'] as int,
      totalUnits: json['total_units'] as int,
      totalAmount: double.parse(json['total_amount'].toString()),
    );
  }
}

class DailyCustomerMetricsModel {
  const DailyCustomerMetricsModel({
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    required this.totalOrders,
    required this.totalUnits,
    required this.totalAmount,
  });

  final int customerId;
  final String customerCode;
  final String customerName;
  final int totalOrders;
  final int totalUnits;
  final double totalAmount;

  factory DailyCustomerMetricsModel.fromJson(Map<String, dynamic> json) {
    return DailyCustomerMetricsModel(
      customerId: json['customer_id'] as int,
      customerCode: json['customer_code'] as String,
      customerName: json['customer_name'] as String,
      totalOrders: json['total_orders'] as int,
      totalUnits: json['total_units'] as int,
      totalAmount: double.parse(json['total_amount'].toString()),
    );
  }
}
