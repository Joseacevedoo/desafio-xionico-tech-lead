import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_navigation_drawer.dart';
import '../../../../core/widgets/session_expired_dialog.dart';
import '../../data/daily_metrics_model.dart';
import '../cubit/metrics_cubit.dart';
import '../cubit/metrics_state.dart';

class MetricsPage extends StatelessWidget {
  const MetricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MetricsCubit>()..loadSummary(),
      child: const _MetricsView(),
    );
  }
}

class _MetricsView extends StatefulWidget {
  const _MetricsView();

  @override
  State<_MetricsView> createState() => _MetricsViewState();
}

class _MetricsViewState extends State<_MetricsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const AppNavigationDrawer(selected: AppDrawerDestination.home),
      appBar: AppBar(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.white,
        title: Text(
          'Inicio',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.white,
            fontSize: 22,
            letterSpacing: 0,
          ),
        ),
      ),
      body: BlocListener<MetricsCubit, MetricsState>(
        listenWhen: (previous, current) {
          return !previous.sessionExpired && current.sessionExpired;
        },
        listener: (context, state) {
          showSessionExpiredDialog(context);
        },
        child: BlocBuilder<MetricsCubit, MetricsState>(
          builder: (context, state) {
            if (state.status == MetricsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == MetricsStatus.failure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message ?? 'No fue posible cargar las métricas.',
                        textAlign: TextAlign.center,
                      ),
                      if (!state.sessionExpired) ...[
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            context.read<MetricsCubit>().loadSummary();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            final summary = state.summary;

            if (summary == null) {
              return const SizedBox.shrink();
            }

            return RefreshIndicator(
              color: AppColors.brandBlue,
              onRefresh: () => context.read<MetricsCubit>().loadSummary(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _SummaryHeader(summary: summary),
                  const SizedBox(height: 14),
                  _MetricCard(
                    icon: Icons.assignment_outlined,
                    title: 'Pedidos del día',
                    value: '${summary.totalOrders}',
                    subtitle: '${summary.confirmedOrders} confirmados',
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Unidades pedidas',
                    value: '${summary.totalUnits}',
                    subtitle: 'Total de productos solicitados',
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    icon: Icons.fact_check_outlined,
                    title: 'Confirmados',
                    value: '${summary.confirmedOrders}',
                    subtitle: 'Pedidos listos para operar',
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    icon: Icons.cancel_presentation_outlined,
                    title: 'Cancelados',
                    value: '${summary.cancelledOrders}',
                    subtitle: 'Pedidos anulados del día',
                  ),
                  if (summary.byCustomer.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _MetricCard(
                      icon: Icons.business_outlined,
                      title: 'Cliente principal',
                      value: '${summary.byCustomer.first.totalOrders}',
                      subtitle: summary.byCustomer.first.customerName,
                    ),
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

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary});

  final DailyMetricsModel summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0x1AFFFFFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights_outlined,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(summary.summaryDate),
                    style: const TextStyle(
                      color: AppColors.whiteMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

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
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF8E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF19A75B), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF121722),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF202633),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();

  return '$day/$month/$year';
}
