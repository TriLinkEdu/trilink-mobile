import '../../../core/models/user_model.dart';
import '../services/auth_service.dart';
import 'auth_repository.dart';

/// Real [AuthRepository] backed by [AuthService] which calls the NestJS backend.
class RealAuthRepository implements AuthRepository {
  final AuthService _authService = AuthService();

  @override
  Future<UserModel> login({
    required String email,
    required String password,
    required String role,
  }) async {
    return _authService.login(email: email, password: password, role: role);
  }

  @override
  Future<UserModel> loginOffline() {
    throw UnimplementedError('Offline login is not supported');
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    throw UnimplementedError('Self-registration is not supported');
  }

  @override
  Future<void> forgotPassword({required String email}) {
    throw UnimplementedError('Forgot password is not supported');
  }

  @override
  Future<void> logout() async {
    await _authService.logout();
  }
}
