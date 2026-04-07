import '../../../core/models/user_model.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<UserModel> login({
    required String email,
    required String password,
    required String role,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return UserModel(
      id: 'student-1',
      name: 'Sara Ahmed',
      email: email,
      role: UserRole.student,
      phone: '+251 912 345 678',
      school: 'Addis Ababa Academy',
      grade: 'Grade 11',
      section: 'Section A',
    );
  }

  @override
  Future<UserModel> loginOffline() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const UserModel(
      id: 'guest-1',
      name: 'Guest Student',
      email: 'guest@offline',
      role: UserRole.student,
      school: 'Offline Mode',
    );
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return UserModel(
      id: 'student-new',
      name: name,
      email: email,
      role: UserRole.student,
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
