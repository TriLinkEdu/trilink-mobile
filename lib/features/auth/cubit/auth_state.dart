import 'package:equatable/equatable.dart';
import '../../../core/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? role;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.role,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isStudent => role == 'student';

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? role,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      role: role ?? this.role,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, role, errorMessage];
}
