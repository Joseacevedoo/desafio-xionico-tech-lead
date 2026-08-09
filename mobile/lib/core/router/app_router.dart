import 'package:go_router/go_router.dart';
import 'package:mobile/features/products/presentation/pages/product_list_page.dart';

import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/auth/presentation/cubit/session_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/metrics/presentation/pages/metrics_page.dart';
import '../../features/orders/pages/order_page.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/orders/presentation/pages/order_confirmation_page.dart';
import '../../features/orders/presentation/pages/order_history_page.dart';
import 'router_refresh_notifier.dart';

class AppRouter {
  AppRouter(this._sessionCubit)
    : _refreshNotifier = RouterRefreshNotifier(_sessionCubit.stream);

  final SessionCubit _sessionCubit;
  final RouterRefreshNotifier _refreshNotifier;

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _refreshNotifier,
    redirect: (context, state) {
      final sessionStatus = _sessionCubit.state.status;

      final isLoginRoute = state.matchedLocation == '/login';

      if (sessionStatus == SessionStatus.checking) {
        return null;
      }

      if (sessionStatus == SessionStatus.unauthenticated) {
        return isLoginRoute ? null : '/login';
      }

      if (sessionStatus == SessionStatus.authenticated && isLoginRoute) {
        return '/inicio';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: '/inicio',
        builder: (context, state) {
          return const MetricsPage();
        },
      ),
      GoRoute(
        path: '/productos',
        builder: (context, state) {
          return const ProductListPage();
        },
      ),
      GoRoute(
        path: '/pedidos',
        builder: (context, state) {
          return const OrderHistoryPage();
        },
      ),
      GoRoute(
        path: '/pedidos/:orderId',
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['orderId']!);

          return OrderDetailPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/pedido',
        builder: (context, state) {
          return const OrderPage();
        },
      ),
      GoRoute(
        path: '/pedido/confirmacion',
        builder: (context, state) {
          return const OrderConfirmationPage();
        },
      ),
    ],
  );
}
