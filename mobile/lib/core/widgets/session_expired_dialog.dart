import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/orders/presentation/cubit/order_cubit.dart';
import '../di/injection.dart';

bool _isShowingSessionExpiredDialog = false;

Future<void> showSessionExpiredDialog(BuildContext context) async {
  if (_isShowingSessionExpiredDialog || !context.mounted) {
    return;
  }

  _isShowingSessionExpiredDialog = true;
  final sessionCubit = context.read<SessionCubit>();
  final orderCubit = getIt<OrderCubit>();

  try {
    await showDialog<void>(
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
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEAB0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE7A600),
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Sesión',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF121722),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'La sesión ha expirado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF202633), fontSize: 14),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 24, 18),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cerrar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  } finally {
    _isShowingSessionExpiredDialog = false;
  }

  orderCubit.clearOrder();
  await sessionCubit.logout();
}
