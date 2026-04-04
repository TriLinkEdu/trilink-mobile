import '../../../../core/models/user_model.dart';
import 'student_profile_repository.dart';

class MockStudentProfileRepository implements StudentProfileRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  UserModel _user = const UserModel(
    id: 'student-1',
    name: 'Sara Ahmed',
    email: 'sara.ahmed@school.edu',
    role: UserRole.student,
    phone: '+251 912 345 678',
    school: 'Addis Ababa Academy',
    grade: 'Grade 11',
    section: 'Section A',
  );

  @override
  Future<UserModel> fetchProfile() async {
    await Future<void>.delayed(_latency);
    return _user;
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
  }) async {
    await Future<void>.delayed(_latency);
    _user = _user.copyWith(
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
    );
    return _user;
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(_latency);
  }
}
