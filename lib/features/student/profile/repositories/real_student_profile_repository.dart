import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import 'student_profile_repository.dart';

class RealStudentProfileRepository implements StudentProfileRepository {
  final ApiClient _api;
  final StorageService _storage;
  final LocalCacheService _cacheService;

  static const Duration _ttl = Duration(seconds: 30);
  static UserModel? _cache;
  static DateTime? _fetchedAt;

  RealStudentProfileRepository({
    ApiClient? apiClient,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService,
       _cacheService = cacheService;

  @override
  Future<UserModel> fetchProfile() async {
    final userId = await _currentUserId();
    _restoreCache(userId);
    if (_cache != null && _fetchedAt != null) {
      final age = DateTime.now().difference(_fetchedAt!);
      if (age < _ttl) return _cache!;
    }

    try {
      final raw = await _api.get(ApiConstants.me);
      final user = UserModel.fromJson(raw);
      await _storage.saveUser(user.toJson());
      _cache = user;
      _fetchedAt = DateTime.now();
      await _cacheService.write(_cacheKey(userId), user.toJson());
      return user;
    } catch (_) {
      if (_cache != null) return _cache!;
      rethrow;
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
  }) async {
    final current = await fetchProfile();
    final nextName = (name ?? current.name).trim();

    String firstName = current.firstName;
    String lastName = current.lastName;
    if (nextName.isNotEmpty) {
      final parts = nextName.split(RegExp(r'\s+'));
      firstName = parts.first;
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    final payload = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
    };
    if (phone != null) {
      payload['phone'] = phone;
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      payload['profileImageFileId'] = avatarUrl;
    }

    await _api.patch(ApiConstants.updateProfile, data: payload);

    final updated = await fetchProfile();
    await _cacheService.write(_cacheKey(updated.id), updated.toJson());
    return updated;
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _api.post(
      ApiConstants.changePassword,
      data: {'currentPassword': oldPassword, 'newPassword': newPassword},
    );
  }

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  String _cacheKey(String userId) =>
      userId.isEmpty ? 'student_profile_v1' : 'student_profile_v1_$userId';

  void _restoreCache(String userId) {
    if (_cache != null) return;
    final entry = _cacheService.read(_cacheKey(userId));
    if (entry == null || entry.data is! Map<String, dynamic>) return;
    _cache = UserModel.fromJson(Map<String, dynamic>.from(entry.data as Map));
    _fetchedAt = entry.savedAt;
  }
}
