import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/dummy_data.dart';
import '../../../core/models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _api = ApiClient();
  final StorageService _storage = StorageService();

  UserModel? _currentUser;
  String? _currentRole;

  UserModel? get currentUser => _currentUser;
  String? get currentRole => _currentRole;

  bool get isStudent => _currentRole == 'student';
  bool get isTeacher => _currentRole == 'teacher';
  bool get isParent => _currentRole == 'parent';

  void setCurrentRole(String role) => _currentRole = role;

  Future<UserModel> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final data = await _api.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
        'role': role,
      });

      await _storage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );

      final userJson = data['user'] as Map<String, dynamic>;
      await _storage.saveUser(userJson);
      await _storage.saveRole(role);

      _currentUser = UserModel.fromJson(userJson);
      _currentRole = role;

      return _currentUser!;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> fetchMe() async {
    try {
      final data = await _api.get(ApiConstants.me);
      _currentUser = UserModel.fromJson(data);
      await _storage.saveUser(data);
      return _currentUser!;
    } catch (_) {
      if (_currentUser != null) return _currentUser!;
      final saved = await _storage.getUser();
      if (saved != null) {
        _currentUser = UserModel.fromJson(saved);
        return _currentUser!;
      }
      _currentUser = UserModel.fromJson(DummyData.teacherUser);
      return _currentUser!;
    }
  }

  Future<void> refreshTokens() async {
    final rt = await _storage.refreshToken;
    if (rt == null) return;

    try {
      final data = await _api.post(ApiConstants.refresh, data: {
        'refreshToken': rt,
      });

      await _storage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );

      if (data['user'] != null) {
        final userJson = data['user'] as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userJson);
        await _storage.saveUser(userJson);
      }
    } catch (_) {
      // Silently fail - dummy mode doesn't need token refresh
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _api.post(ApiConstants.changePassword, data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } catch (_) {
      // In dummy mode, just succeed silently
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _currentRole = null;
    await _storage.clearAll();
  }

  Future<bool> tryRestoreSession() async {
    final hasTokens = await _storage.hasTokens;
    final savedUser = await _storage.getUser();
    if (savedUser != null) {
      _currentUser = UserModel.fromJson(savedUser);
      _currentRole = await _storage.getRole();
      return true;
    }
    if (!hasTokens) return false;
    return false;
  }
}
