import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/orders/presentation/cubit/order_cubit.dart';
import '../di/injection.dart';
import '../theme/app_colors.dart';

enum AppDrawerDestination { home, products, orders }

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({required this.selected, super.key});

  final AppDrawerDestination selected;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final user = session.user;
    final displayName = user?.displayName ?? 'Operador';
    final username = user?.username ?? 'usuario';

    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _DrawerHeader(displayName: displayName, username: username),
            const SizedBox(height: 10),
            _DrawerItem(
              icon: Icons.house_outlined,
              label: 'Inicio',
              selected: selected == AppDrawerDestination.home,
              onTap: () {
                _goTo(context, '/inicio');
              },
            ),
            _DrawerItem(
              icon: Icons.inventory_2_outlined,
              label: 'Productos',
              selected: selected == AppDrawerDestination.products,
              onTap: () {
                _goTo(context, '/productos');
              },
            ),
            _DrawerItem(
              icon: Icons.assignment_outlined,
              label: 'Pedidos',
              selected: selected == AppDrawerDestination.orders,
              onTap: () {
                _goTo(context, '/pedidos');
              },
            ),
            const Spacer(),
            const Divider(height: 1, color: AppColors.border),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Cerrar sesión',
              destructive: true,
              onTap: () {
                _confirmLogout(context);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _goTo(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF8A5A12),
                size: 44,
              ),
              const SizedBox(height: 22),
              const Text(
                '¿Cerrar sesión?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF121722),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Se cerrará tu sesión actual.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF202633), fontSize: 15),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(false);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.brandBlue,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text('NO'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(true);
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text('SÍ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    Navigator.of(context).pop();
    getIt<OrderCubit>().clearOrder();
    await context.read<SessionCubit>().logout();
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.displayName, required this.username});

  final String displayName;
  final String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(28)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.white,
            child: Text(
              _initials(displayName),
              style: const TextStyle(
                color: AppColors.brandBlue,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nombre y Apellido',
                  style: TextStyle(
                    color: AppColors.whiteMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Usuario',
                  style: TextStyle(
                    color: AppColors.whiteMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFF9B1C1C)
        : selected
        ? AppColors.brandBlue
        : const Color(0xFF4F5663);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        minLeadingWidth: 24,
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: selected || destructive
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
        selected: selected,
        selectedTileColor: const Color(0xFFEAF8F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return 'OP';
  }

  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }

  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}
