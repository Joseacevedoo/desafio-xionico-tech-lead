import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../data/auth_repository.dart';
import 'session_state.dart';

class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._secureStorage, this._authRepository)
    : super(const SessionState.checking());

  final SecureStorage _secureStorage;
  final AuthRepository _authRepository;

  Future<void> restoreSession() async {
    final token = await _secureStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      emit(const SessionState.unauthenticated());
      return;
    }

    try {
      final user = await _authRepository.validateSession();

      emit(SessionState.authenticated(user));
    } catch (_) {
      await _secureStorage.deleteAccessToken();

      emit(const SessionState.unauthenticated());
    }
  }

  void authenticated(AuthUserModel user) {
    emit(SessionState.authenticated(user));
  }

  Future<void> logout() async {
    await _secureStorage.deleteAccessToken();

    emit(const SessionState.unauthenticated());
  }
}
