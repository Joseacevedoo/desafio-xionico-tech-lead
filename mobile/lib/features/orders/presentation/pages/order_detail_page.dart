import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/session_expired_dialog.dart';
import '../../data/order_repository.dart';
import '../cubit/order_detail_cubit.dart';
import '../cubit/order_detail_state.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrderDetailCubit>()..loadOrder(orderId),
      child: _OrderDetailView(orderId: orderId),
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView({required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.white,
        title: Text(
          'Detalle pedido',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.white,
            fontSize: 22,
            letterSpacing: 0,
          ),
        ),
      ),
      body: BlocListener<OrderDetailCubit, OrderDetailState>(
        listenWhen: (previous, current) {
          return !previous.sessionExpired && current.sessionExpired;
        },
        listener: (context, state) {
          showSessionExpiredDialog(context);
        },
        child: BlocBuilder<OrderDetailCubit, OrderDetailState>(
          builder: (context, state) {
            if (state.status == OrderDetailStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == OrderDetailStatus.failure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message ?? 'No fue posible cargar el pedido.',
                        textAlign: TextAlign.center,
                      ),
                      if (!state.sessionExpired) ...[
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            context.read<OrderDetailCubit>().loadOrder(orderId);
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            final order = state.order;

            if (order == null) {
              return const SizedBox.shrink();
            }

            return RefreshIndicator(
              color: AppColors.brandBlue,
              onRefresh: () =>
                  context.read<OrderDetailCubit>().loadOrder(orderId),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _OrderHeader(order: order),
                  const SizedBox(height: 12),
                  for (final item in order.items) ...[
                    _OrderDetailItemCard(item: item),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});

  final OrderDetailModel order;

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.orderNumber,
              style: const TextStyle(
                color: Color(0xFF121722),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${order.customer.name} · ${_formatDate(order.createdAt)}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatusPill(status: order.status),
                const Spacer(),
                Text(
                  _formatPrice(order.totalAmount),
                  style: const TextStyle(
                    color: Color(0xFF121722),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Creado por ${order.createdBy.displayName}',
              style: const TextStyle(
                color: Color(0xFF4F5663),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailItemCard extends StatelessWidget {
  const _OrderDetailItemCard({required this.item});

  final OrderDetailItemModel item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
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
                color: Color(0xFF19A75B),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF121722),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Código  ${item.productCode}',
                    style: const TextStyle(
                      color: Color(0xFF656D7A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity} x ${_formatPrice(item.unitPrice)}',
                          style: const TextStyle(
                            color: Color(0xFF4F5663),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _formatStatus(status),
        style: const TextStyle(
          color: Color(0xFF19A75B),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatStatus(String status) {
  return switch (status) {
    'CONFIRMED' => 'Confirmado',
    'CANCELLED' => 'Cancelado',
    _ => status,
  };
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();

  return '$day/$month/$year';
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
