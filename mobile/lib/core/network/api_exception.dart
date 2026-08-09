class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });

  final String code;
  final String message;
  final int? statusCode;
  final dynamic details;

  bool get isSessionExpired => statusCode == 401 || code == 'SESSION_INVALID';

  @override
  String toString() => message;
}
