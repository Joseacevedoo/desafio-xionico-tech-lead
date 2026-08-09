import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/session_expired_dialog.dart';
import '../data/order_draft_item.dart';
import '../presentation/cubit/order_cubit.dart';
import '../presentation/cubit/order_state.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<OrderCubit>(),
      child: const _OrderView(),
    );
  }
}

class _OrderView extends StatefulWidget {
  const _OrderView();

  @override
  State<_OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<_OrderView> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state.status == OrderStatus.success) {
          context.go('/pedido/confirmacion');
          return;
        }

        if (state.status == OrderStatus.failure && state.message != null) {
          if (state.sessionExpired) {
            showSessionExpiredDialog(context);
            return;
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.brandBlue,
            foregroundColor: AppColors.white,
            leading: IconButton(
              tooltip: 'Volver a productos',
              onPressed: () {
                context.go('/productos');
              },
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(
              'Nuevo pedido',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.white,
                fontSize: 22,
                letterSpacing: 0,
              ),
            ),
          ),
          body: state.items.isEmpty
              ? const _EmptyOrder()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = state.items[index];

                          return _OrderItemCard(
                            item: item,
                            onDecrement: () {
                              context.read<OrderCubit>().decrementQuantity(
                                item.product.id,
                              );
                            },
                            onIncrement: () {
                              context.read<OrderCubit>().incrementQuantity(
                                item.product.id,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    _OrderSummary(
                      totalQuantity: state.totalQuantity,
                      estimatedTotal: state.estimatedTotal,
                      isSubmitting: state.status == OrderStatus.submitting,
                      onSubmit: () {
                        context.read<OrderCubit>().submitOrder();
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _EmptyOrder extends StatelessWidget {
  const _EmptyOrder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Color(0xFF19A75B),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Todavía no agregaste productos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF303642),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({
    required this.item,
    required this.onDecrement,
    required this.onIncrement,
  });

  final OrderDraftItem item;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF8E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: Color(0xFF19A75B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF121722),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Código  '),
                            TextSpan(
                              text: item.product.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          color: Color(0xFF656D7A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _QuantityStepper(
                  quantity: item.quantity,
                  onDecrement: onDecrement,
                  onIncrement: onIncrement,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Precio unitario',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatPrice(item.product.unitPrice),
                          style: const TextStyle(
                            color: Color(0xFF202633),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatPrice(item.subtotal),
                        style: const TextStyle(
                          color: Color(0xFF202633),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Restar unidad',
            onPressed: onDecrement,
            icon: const Icon(Icons.remove, size: 18),
            color: AppColors.brandBlue,
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              fixedSize: const Size(32, 32),
              padding: EdgeInsets.zero,
            ),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF202633),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sumar unidad',
            onPressed: onIncrement,
            icon: const Icon(Icons.add, size: 18),
            color: AppColors.brandBlue,
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              fixedSize: const Size(32, 32),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.totalQuantity,
    required this.estimatedTotal,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final int totalQuantity;
  final double estimatedTotal;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Productos',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalQuantity',
                          style: const TextStyle(
                            color: Color(0xFF202633),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total estimado',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatPrice(estimatedTotal),
                        style: const TextStyle(
                          color: Color(0xFF121722),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: isSubmitting ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.textMuted,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text(
                        'Confirmar pedido',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatPrice(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final integer = parts.first;
  final decimal = parts.last;
  final buffer = StringBuffer();

  for (var index = 0; index < integer.length; index++) {
    final positionFromEnd = integer.length - index;
    buffer.write(integer[index]);

    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  return '\$ ${buffer.toString()},$decimal';
}
