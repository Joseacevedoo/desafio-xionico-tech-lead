import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/metrics/data/metrics_repository.dart';
import '../../features/metrics/presentation/cubit/metrics_cubit.dart';
import '../../features/orders/data/order_repository.dart';
import '../../features/orders/presentation/cubit/order_detail_cubit.dart';
import '../../features/orders/presentation/cubit/order_history_cubit.dart';
import '../../features/orders/presentation/cubit/order_cubit.dart';
import '../../features/products/data/product_repository.dart';
import '../../features/products/presentation/cubit/product_cubit.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../router/app_router.dart';
import '../storage/secure_storage.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Almacenamiento seguro.
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  getIt.registerLazySingleton<SecureStorage>(
    () => SecureStorage(getIt<FlutterSecureStorage>()),
  );

  // Cliente HTTP.
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(getIt<SecureStorage>()));

    return dio;
  });

  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt<Dio>()));

  // Repositorios.
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      dio: getIt<Dio>(),
      secureStorage: getIt<SecureStorage>(),
    ),
  );

  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepository(getIt<Dio>()),
  );

  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepository(getIt<Dio>()),
  );

  getIt.registerLazySingleton<MetricsRepository>(
    () => MetricsRepository(getIt<Dio>()),
  );

  // Estado global de sesión.
  getIt.registerLazySingleton<SessionCubit>(
    () => SessionCubit(getIt<SecureStorage>(), getIt<AuthRepository>()),
  );

  // Cubits por funcionalidad.
  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(getIt<AuthRepository>(), getIt<SessionCubit>()),
  );

  getIt.registerFactory<ProductCubit>(
    () => ProductCubit(getIt<ProductRepository>()),
  );

  getIt.registerFactory<MetricsCubit>(
    () => MetricsCubit(getIt<MetricsRepository>()),
  );

  getIt.registerFactory<OrderHistoryCubit>(
    () => OrderHistoryCubit(getIt<OrderRepository>()),
  );

  getIt.registerFactory<OrderDetailCubit>(
    () => OrderDetailCubit(getIt<OrderRepository>()),
  );

  // El borrador del pedido debe sobrevivir mientras navegamos.
  getIt.registerLazySingleton<OrderCubit>(
    () => OrderCubit(getIt<OrderRepository>()),
  );

  // Enrutador global.
  getIt.registerLazySingleton<AppRouter>(
    () => AppRouter(getIt<SessionCubit>()),
  );
}
