import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_navigation_drawer.dart';
import '../../../../core/widgets/session_expired_dialog.dart';
import '../../data/order_repository.dart';
import '../cubit/order_history_cubit.dart';
import '../cubit/order_history_state.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrderHistoryCubit>()..loadOrders(),
      child: const _OrderHistoryView(),
    );
  }
}

class _OrderHistoryView extends StatefulWidget {
  const _OrderHistoryView();

  @override
  State<_OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<_OrderHistoryView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const AppNavigationDrawer(selected: AppDrawerDestination.orders),
      appBar: AppBar(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.white,
        title: Text(
          'Pedidos',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.white,
            fontSize: 22,
            letterSpacing: 0,
          ),
        ),
      ),
      body: BlocListener<OrderHistoryCubit, OrderHistoryState>(
        listenWhen: (previous, current) {
          return !previous.sessionExpired && current.sessionExpired;
        },
        listener: (context, state) {
          showSessionExpiredDialog(context);
        },
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
                builder: (context, state) {
                  if (state.status == OrderHistoryStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == OrderHistoryStatus.failure) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.message ??
                                  'No fue posible cargar los pedidos.',
                              textAlign: TextAlign.center,
                            ),
                            if (!state.sessionExpired) ...[
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () {
                                  context
                                      .read<OrderHistoryCubit>()
                                      .loadOrders();
                                },
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  if (state.items.isEmpty) {
                    return const Center(
                      child: Text('Todavía no hay pedidos registrados.'),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.brandBlue,
                    onRefresh: () => context
                        .read<OrderHistoryCubit>()
                        .loadOrders(page: state.page),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final order = state.items[index];

                        return _OrderHistoryCard(
                          order: order,
                          onTap: () {
                            context.push('/pedidos/${order.id}');
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
              builder: (context, state) {
                if (state.status != OrderHistoryStatus.success ||
                    state.totalItems == 0) {
                  return const SizedBox.shrink();
                }

                return DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            tooltip: 'Página anterior',
                            onPressed: state.page > 1
                                ? () {
                                    context
                                        .read<OrderHistoryCubit>()
                                        .previousPage();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            'Página ${state.page} de ${state.totalPages} '
                            '· ${state.totalItems} pedidos',
                            style: const TextStyle(
                              color: Color(0xFF303642),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Página siguiente',
                            onPressed: state.page < state.totalPages
                                ? () {
                                    context
                                        .read<OrderHistoryCubit>()
                                        .nextPage();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({required this.order, required this.onTap});

  final OrderListItemModel order;
  final VoidCallback onTap;

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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
                  Icons.assignment_outlined,
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
                      order.orderNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF121722),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                            '${order.totalUnits} unidades · ${_formatStatus(order.status)}',
                            style: const TextStyle(
                              color: Color(0xFF4F5663),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _formatPrice(order.totalAmount),
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
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
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
