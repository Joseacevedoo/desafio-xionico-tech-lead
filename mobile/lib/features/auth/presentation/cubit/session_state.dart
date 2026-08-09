import 'package:equatable/equatable.dart';

import '../../data/auth_repository.dart';

enum SessionStatus { checking, authenticated, unauthenticated }

class SessionState extends Equatable {
  const SessionState({required this.status, this.user});

  final SessionStatus status;
  final AuthUserModel? user;

  const SessionState.checking() : status = SessionStatus.checking, user = null;

  const SessionState.authenticated(this.user)
    : status = SessionStatus.authenticated;

  const SessionState.unauthenticated()
    : status = SessionStatus.unauthenticated,
      user = null;

  @override
  List<Object?> get props => [status, user];
}
