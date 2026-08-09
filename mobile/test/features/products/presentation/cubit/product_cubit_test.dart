import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/products/data/product_model.dart';
import 'package:mobile/features/products/data/product_repository.dart';
import 'package:mobile/features/products/presentation/cubit/product_cubit.dart';
import 'package:mobile/features/products/presentation/cubit/product_state.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository repository;

  setUp(() {
    repository = MockProductRepository();
  });

  group('ProductCubit', () {
    blocTest<ProductCubit, ProductState>(
      'carga productos correctamente',
      build: () {
        when(
          () => repository.getProducts(page: 1, pageSize: 20, search: null),
        ).thenAnswer(
          (_) async => const ProductListResult(
            items: [
              ProductModel(
                id: 1,
                code: 'PROD-001',
                name: 'Arroz',
                unitPrice: 1850,
                availableStock: 10,
              ),
            ],
            page: 1,
            pageSize: 20,
            totalItems: 1,
            totalPages: 1,
          ),
        );

        return ProductCubit(repository);
      },
      act: (cubit) => cubit.loadProducts(),
      expect: () => [
        isA<ProductState>().having(
          (state) => state.status,
          'status',
          ProductStatus.loading,
        ),
        isA<ProductState>()
            .having((state) => state.status, 'status', ProductStatus.success)
            .having((state) => state.items.length, 'items', 1)
            .having((state) => state.totalItems, 'totalItems', 1),
      ],
    );

    blocTest<ProductCubit, ProductState>(
      'normaliza búsqueda y la envía al repository',
      build: () {
        when(
          () => repository.getProducts(page: 1, pageSize: 20, search: 'arroz'),
        ).thenAnswer(
          (_) async => const ProductListResult(
            items: [],
            page: 1,
            pageSize: 20,
            totalItems: 0,
            totalPages: 0,
          ),
        );

        return ProductCubit(repository);
      },
      act: (cubit) => cubit.loadProducts(search: 'arroz'),
      verify: (_) {
        verify(
          () => repository.getProducts(page: 1, pageSize: 20, search: 'arroz'),
        ).called(1);
      },
    );

    blocTest<ProductCubit, ProductState>(
      'marca sesión expirada cuando la API responde 401',
      build: () {
        when(
          () => repository.getProducts(page: 1, pageSize: 20, search: null),
        ).thenThrow(
          const ApiException(
            code: 'SESSION_INVALID',
            message: 'Token inválido',
            statusCode: 401,
          ),
        );

        return ProductCubit(repository);
      },
      act: (cubit) => cubit.loadProducts(),
      expect: () => [
        isA<ProductState>().having(
          (state) => state.status,
          'status',
          ProductStatus.loading,
        ),
        isA<ProductState>()
            .having((state) => state.status, 'status', ProductStatus.failure)
            .having((state) => state.sessionExpired, 'sessionExpired', true)
            .having(
              (state) => state.message,
              'message',
              'La sesión ha expirado.',
            ),
      ],
    );
  });
}
