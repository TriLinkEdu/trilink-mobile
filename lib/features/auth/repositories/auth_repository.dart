import '../../../core/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> loginOffline();
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
  });
  Future<void> forgotPassword({required String email});
  Future<void> logout();
}
