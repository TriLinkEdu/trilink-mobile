import '../../../../core/models/user_model.dart';

abstract class StudentProfileRepository {
  Future<UserModel> fetchProfile();
  Future<UserModel> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
  });
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}
