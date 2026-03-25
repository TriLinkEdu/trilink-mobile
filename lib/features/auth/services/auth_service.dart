import '../../../core/models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _currentRole;
  UserModel? _currentUser;

  String? get currentRole => _currentRole;
  UserModel? get currentUser => _currentUser;

  bool get isStudent => _currentRole == 'student';
  bool get isLoggedIn => _currentUser != null;

  void setCurrentRole(String role) {
    _currentRole = role;
  }

  Future<void> login({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentRole = 'student';
    _currentUser = UserModel(
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

  Future<void> loginOffline() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentRole = 'student';
    _currentUser = const UserModel(
      id: 'guest-1',
      name: 'Guest Student',
      email: 'guest@offline',
      role: UserRole.student,
      school: 'Offline Mode',
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentRole = role;
    _currentUser = UserModel(
      id: 'student-new',
      name: name,
      email: email,
      role: UserRole.student,
    );
  }

  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentRole = null;
    _currentUser = null;
  }

  Future<void> forgotPassword({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  void updateUser(UserModel user) {
    _currentUser = user;
  }
}
