import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/dummy_data.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/socket_service.dart';

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

      // Fetch complete user profile after login
      print('DEBUG AUTH: Login successful, fetching complete profile...');
      try {
        await fetchMe();
        print('DEBUG AUTH: Complete profile fetched after login');
      } catch (e) {
        print('DEBUG AUTH: Failed to fetch complete profile after login: $e');
        // Continue with login data if fetchMe fails
      }

      // Connect WebSocket for real-time chat
      unawaited(_connectSocket());

      return _currentUser!;
    } catch (e) {
      rethrow;
    }
  }

  /// Connect SocketService after a successful login.
  Future<void> _connectSocket() async {
    try {
      final token = await _storage.accessToken;
      if (token != null && token.isNotEmpty) {
        await SocketService().connect(token);
      }
    } catch (_) {
      // Non-fatal — chat will work in REST-only mode
    }
  }

  Future<UserModel> fetchMe() async {
    try {
      print('DEBUG AUTH: Fetching user data from API...');
      final data = await _api.get(ApiConstants.me);
      print('DEBUG AUTH: Raw API response: $data');
      print('DEBUG AUTH: Phone from API: "${data['phone']}"');
      _currentUser = UserModel.fromJson(data);
      print('DEBUG AUTH: Parsed user model phone: "${_currentUser?.phone}"');
      await _storage.saveUser(data);
      print('DEBUG AUTH: User data updated and saved');
      return _currentUser!;
    } catch (e) {
      print('DEBUG AUTH: Error fetching user data: $e');
      if (_currentUser != null) {
        print('DEBUG AUTH: Returning cached user data - phone: "${_currentUser?.phone}"');
        return _currentUser!;
      }
      final saved = await _storage.getUser();
      if (saved != null) {
        print('DEBUG AUTH: Returning saved user data - phone: "${saved['phone']}"');
        _currentUser = UserModel.fromJson(saved);
        return _currentUser!;
      }
      print('DEBUG AUTH: Returning dummy user data');
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
    SocketService().setPresence('offline');
    SocketService().disconnect();
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
      
      // Fetch fresh user data if we have tokens
      if (hasTokens) {
        print('DEBUG AUTH: Session restored, fetching fresh profile data...');
        try {
          await fetchMe();
          print('DEBUG AUTH: Fresh profile data fetched after session restore');
        } catch (e) {
          print('DEBUG AUTH: Failed to fetch fresh profile after session restore: $e');
          // Continue with cached data if fetchMe fails
        }
        // Reconnect WebSocket
        unawaited(_connectSocket());
      }
      
      return true;
    }
    if (!hasTokens) return false;
    return false;
  }
}

// Helper to fire-and-forget async calls
void unawaited(Future<void> future) {
  future.catchError((_) {});
}
