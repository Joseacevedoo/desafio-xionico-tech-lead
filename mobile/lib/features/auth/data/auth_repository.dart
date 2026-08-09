import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage.dart';

class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.username,
    required this.displayName,
  });

  final int id;
  final String username;
  final String displayName;

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
    );
  }
}

class AuthRepository {
  AuthRepository({required Dio dio, required SecureStorage secureStorage})
    : _dio = dio,
      _secureStorage = secureStorage;

  final Dio _dio;
  final SecureStorage _secureStorage;

  Future<AuthUserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {'username': username, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      final user = AuthUserModel.fromJson(data['user'] as Map<String, dynamic>);

      await _secureStorage.saveAccessToken(token);

      return user;
    } on DioException catch (error) {
      final response = error.response;

      if (response?.data is Map<String, dynamic>) {
        final data = response!.data as Map<String, dynamic>;

        throw ApiException(
          code: data['code']?.toString() ?? 'API_ERROR',
          message:
              data['message']?.toString() ??
              'Ocurrió un error al comunicarse con el servidor.',
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

  Future<AuthUserModel> validateSession() async {
    try {
      final response = await _dio.get('/api/v1/auth/me');
      final data = response.data as Map<String, dynamic>;

      return AuthUserModel.fromJson(data);
    } on DioException catch (error) {
      final response = error.response;

      if (response?.statusCode == 401) {
        await _secureStorage.deleteAccessToken();

        throw const ApiException(
          code: 'SESSION_INVALID',
          message: 'La sesión ya no es válida.',
          statusCode: 401,
        );
      }

      if (response?.data is Map<String, dynamic>) {
        final data = response!.data as Map<String, dynamic>;

        throw ApiException(
          code: data['code']?.toString() ?? 'API_ERROR',
          message:
              data['message']?.toString() ??
              'No fue posible validar la sesión.',
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
