/// Authentication service handling login, register, logout.
/// TODO: Implement API calls.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _currentRole;

  String? get currentRole => _currentRole;

  bool get isStudent => _currentRole == 'student';

  void setCurrentRole(String role) {
    _currentRole = role;
  }

  Future<void> login({required String email, required String password}) async {
    // TODO: Implement
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    // TODO: Implement
  }

  Future<void> logout() async {
    _currentRole = null;
    // TODO: Implement
  }

  Future<void> forgotPassword({required String email}) async {
    // TODO: Implement
  }
}
