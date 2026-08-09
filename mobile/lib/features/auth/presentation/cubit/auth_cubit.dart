import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';
import 'auth_state.dart';
import 'session_cubit.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository, this._sessionCubit) : super(const AuthState());

  final AuthRepository _repository;
  final SessionCubit _sessionCubit;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(const AuthState(status: AuthStatus.loading));

    try {
      final user = await _repository.login(
        username: username.trim(),
        password: password,
      );

      _sessionCubit.authenticated(user);

      emit(const AuthState(status: AuthStatus.success));
    } on ApiException catch (error) {
      emit(AuthState(status: AuthStatus.failure, message: error.message));
    } catch (_) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          message: 'Ocurrió un error inesperado.',
        ),
      );
    }
  }
}
