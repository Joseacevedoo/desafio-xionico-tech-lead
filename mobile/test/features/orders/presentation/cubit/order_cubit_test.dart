import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/orders/data/order_repository.dart';
import 'package:mobile/features/orders/presentation/cubit/order_cubit.dart';
import 'package:mobile/features/orders/presentation/cubit/order_state.dart';
import 'package:mobile/features/products/data/product_model.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late MockOrderRepository repository;

  const product = ProductModel(
    id: 1,
    code: 'PROD-001',
    name: 'Arroz',
    unitPrice: 1850,
    availableStock: 10,
  );

  setUp(() {
    repository = MockOrderRepository();
  });

  group('OrderCubit', () {
    blocTest<OrderCubit, OrderState>(
      'agrega un producto con cantidad inicial 1',
      build: () => OrderCubit(repository),
      act: (cubit) => cubit.addProduct(product),
      verify: (cubit) {
        expect(cubit.state.items.length, 1);
        expect(cubit.state.items.first.quantity, 1);
        expect(cubit.state.totalQuantity, 1);
        expect(cubit.state.estimatedTotal, 1850);
      },
    );

    blocTest<OrderCubit, OrderState>(
      'incrementa cantidad si el producto ya existe',
      build: () => OrderCubit(repository),
      act: (cubit) {
        cubit.addProduct(product);
        cubit.addProduct(product);
      },
      verify: (cubit) {
        expect(cubit.state.items.length, 1);
        expect(cubit.state.items.first.quantity, 2);
        expect(cubit.state.totalQuantity, 2);
        expect(cubit.state.estimatedTotal, 3700);
      },
    );

    blocTest<OrderCubit, OrderState>(
      'elimina el producto cuando la cantidad llega a cero',
      build: () => OrderCubit(repository),
      act: (cubit) {
        cubit.addProduct(product);
        cubit.decrementQuantity(product.id);
      },
      verify: (cubit) {
        expect(cubit.state.items, isEmpty);
        expect(cubit.state.totalQuantity, 0);
      },
    );

    blocTest<OrderCubit, OrderState>(
      'registra correctamente el pedido',
      build: () {
        when(
          () => repository.createOrder(
            items: any(named: 'items'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenAnswer(
          (_) async => const CreateOrderResult(
            id: 10,
            orderNumber: 'ORD-20260807-000010',
            status: 'CONFIRMED',
            totalAmount: 4600,
            isReplay: false,
          ),
        );

        return OrderCubit(repository);
      },
      seed: () {
        final cubit = OrderCubit(repository);
        cubit.addProduct(product);
        return cubit.state;
      },
      act: (cubit) => cubit.submitOrder(),
      expect: () => [
        isA<OrderState>().having(
          (state) => state.status,
          'status',
          OrderStatus.submitting,
        ),
        isA<OrderState>()
            .having((state) => state.status, 'status', OrderStatus.success)
            .having((state) => state.orderId, 'orderId', 10)
            .having((state) => state.totalAmount, 'totalAmount', 4600)
            .having(
              (state) => state.orderNumber,
              'orderNumber',
              'ORD-20260807-000010',
            ),
      ],
    );

    blocTest<OrderCubit, OrderState>(
      'marca sesión expirada cuando la creación del pedido responde 401',
      build: () {
        when(
          () => repository.createOrder(
            items: any(named: 'items'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenThrow(
          const ApiException(
            code: 'SESSION_INVALID',
            message: 'Token inválido',
            statusCode: 401,
          ),
        );

        return OrderCubit(repository);
      },
      seed: () {
        final cubit = OrderCubit(repository);
        cubit.addProduct(product);
        return cubit.state;
      },
      act: (cubit) => cubit.submitOrder(),
      expect: () => [
        isA<OrderState>().having(
          (state) => state.status,
          'status',
          OrderStatus.submitting,
        ),
        isA<OrderState>()
            .having((state) => state.status, 'status', OrderStatus.failure)
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
