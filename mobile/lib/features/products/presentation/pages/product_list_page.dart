import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_navigation_drawer.dart';
import '../../../../core/widgets/session_expired_dialog.dart';
import '../../../orders/presentation/cubit/order_cubit.dart';
import '../../../orders/presentation/cubit/order_state.dart';
import '../../data/product_model.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductCubit>()..loadProducts(),
      child: const _ProductListView(),
    );
  }
}

class _ProductListView extends StatefulWidget {
  const _ProductListView();

  @override
  State<_ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<_ProductListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    context.read<ProductCubit>().loadProducts(
      page: 1,
      search: _searchController.text,
    );
  }

  Future<void> _refreshProducts(ProductState state) {
    return context.read<ProductCubit>().loadProducts(
      page: state.page,
      search: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppNavigationDrawer(
        selected: AppDrawerDestination.products,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.white,
        title: Text(
          'Productos',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            letterSpacing: 0,
            color: AppColors.white,
            fontSize: 22,
          ),
        ),
        actions: [
          BlocProvider.value(
            value: getIt<OrderCubit>(),
            child: BlocBuilder<OrderCubit, OrderState>(
              builder: (context, state) {
                return IconButton(
                  tooltip: 'Pedido actual (${state.totalQuantity})',
                  onPressed: state.totalQuantity > 0
                      ? () {
                          context.push('/pedido');
                        }
                      : null,
                  color: AppColors.white,
                  disabledColor: AppColors.whiteMuted,
                  icon: Badge(
                    isLabelVisible: state.totalQuantity > 0,
                    label: Text('${state.totalQuantity}'),
                    child: const Icon(Icons.assignment_add),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: BlocListener<ProductCubit, ProductState>(
        listenWhen: (previous, current) {
          return !previous.sessionExpired && current.sessionExpired;
        },
        listener: (context, state) {
          showSessionExpiredDialog(context);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nombre o código',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textMuted,
                          size: 22,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(
                            color: AppColors.brandBlue,
                            width: 1.4,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _search,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Buscar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  if (state.status == ProductStatus.loading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandBlue,
                      ),
                    );
                  }

                  if (state.status == ProductStatus.failure) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.message ??
                                  'No fue posible cargar los productos.',
                              textAlign: TextAlign.center,
                            ),
                            if (!state.sessionExpired) ...[
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () {
                                  context.read<ProductCubit>().loadProducts(
                                    search: _searchController.text,
                                  );
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
                      child: Text('No se encontraron productos.'),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.brandBlue,
                    onRefresh: () => _refreshProducts(state),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final product = state.items[index];

                        return _ProductCard(
                          product: product,
                          onAdd: product.availableStock > 0
                              ? () {
                                  getIt<OrderCubit>().addProduct(product);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product.name} agregado.',
                                      ),
                                      duration: const Duration(
                                        milliseconds: 700,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state.status != ProductStatus.success ||
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
                                    context.read<ProductCubit>().previousPage();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            'Página ${state.page} de ${state.totalPages} '
                            '· ${state.totalItems} productos',
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
                                    context.read<ProductCubit>().nextPage();
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onAdd});

  final ProductModel product;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final availableStock = product.availableStock;
    final hasStock = availableStock > 0;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: hasStock
                    ? const Color(0xFFDDF8E6)
                    : const Color(0xFFF0F1F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: hasStock ? const Color(0xFF19A75B) : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name.toUpperCase(),
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
                          text: product.code,
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
                  if (product.description != null &&
                      product.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Stock: $availableStock unidades',
                          style: const TextStyle(
                            color: Color(0xFF4F5663),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _formatPrice(product.unitPrice),
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
            IconButton(
              tooltip: hasStock ? 'Agregar al pedido' : 'Sin stock',
              onPressed: onAdd,
              style: IconButton.styleFrom(
                backgroundColor: hasStock
                    ? const Color(0xFFEAF8F0)
                    : const Color(0xFFE6E8ED),
                foregroundColor: hasStock
                    ? const Color(0xFF19A75B)
                    : AppColors.textMuted,
                disabledForegroundColor: AppColors.textMuted,
                minimumSize: const Size(34, 34),
                fixedSize: const Size(34, 34),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.post_add, size: 19),
            ),
          ],
        ),
      ),
    );
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
}
