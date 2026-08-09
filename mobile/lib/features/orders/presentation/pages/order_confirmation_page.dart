import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/order_cubit.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<OrderCubit>(),
      child: const _OrderConfirmationView(),
    );
  }
}

class _OrderConfirmationView extends StatelessWidget {
  const _OrderConfirmationView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrderCubit>().state;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.brandBlue,
        title: const Text(
          'Pedido confirmado',
          style: TextStyle(color: AppColors.white),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 72),
                      const SizedBox(height: 24),
                      Text(
                        'Pedido registrado correctamente',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _InfoRow(
                        label: 'Número',
                        value: state.orderNumber ?? '-',
                      ),
                      const Divider(),
                      const _InfoRow(label: 'Estado', value: 'CONFIRMED'),
                      const Divider(),
                      _InfoRow(
                        label: 'Productos',
                        value: '${state.totalQuantity}',
                      ),
                      const Divider(),
                      _InfoRow(
                        label: 'Total confirmado',
                        value: _formatPrice(
                          state.totalAmount ?? state.estimatedTotal,
                        ),
                      ),

                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () {
                          context.read<OrderCubit>().clearOrder();

                          context.go('/productos');
                        },
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('Volver al catálogo de productos'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatPrice(double value) {
  return '\$${value.toStringAsFixed(2)}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
