import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import 'student_profile_repository.dart';

class RealStudentProfileRepository implements StudentProfileRepository {
  final ApiClient _api;
  final StorageService _storage;

  RealStudentProfileRepository({
    ApiClient? apiClient,
    required StorageService storageService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService;

  @override
  Future<UserModel> fetchProfile() async {
    final raw = await _api.get(ApiConstants.me);
    final user = UserModel.fromJson(raw);
    await _storage.saveUser(user.toJson());
    return user;
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

    return fetchProfile();
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
}
