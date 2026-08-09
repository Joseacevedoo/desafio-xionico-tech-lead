import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/presentation/cubit/session_cubit.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final SessionCubit _sessionCubit;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();

    _sessionCubit = getIt<SessionCubit>();
    _appRouter = getIt<AppRouter>();

    _sessionCubit.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _sessionCubit,
      child: MaterialApp.router(
        title: 'Xionico Gestión de Pedidos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.brandBlue,
            primary: AppColors.brandBlue,
          ),
        ),
        routerConfig: _appRouter.router,
      ),
    );
  }
}
