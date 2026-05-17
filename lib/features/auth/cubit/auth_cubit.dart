import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/chat_socket_service.dart';
import '../repositories/auth_repository.dart';
import 'auth_state.dart';

export 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;
  final ChatSocketService? _chatSocket;
  final List<void Function()> _onLogout;

  AuthCubit({
    required AuthRepository repository,
    ChatSocketService? chatSocketService,
    List<void Function()> onLogout = const [],
  })  : _repository = repository,
        _chatSocket = chatSocketService,
        _onLogout = onLogout,
        super(const AuthState());

  UserModel? get currentUser => state.user;
  String? get currentRole => state.role;

  Future<void> login({
    required String email,
    required String password,
    required String role,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _repository.login(email: email, password: password, role: role);
      emit(AuthState(
        status: AuthStatus.authenticated,
        user: user,
        role: role,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
      rethrow;
    }
  }

  Future<void> loginOffline() async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _repository.loginOffline();
      emit(AuthState(
        status: AuthStatus.authenticated,
        user: user,
        role: 'student',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _repository.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      emit(AuthState(
        status: AuthStatus.authenticated,
        user: user,
        role: role,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> forgotPassword({required String email}) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _repository.forgotPassword(email: email);
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> logout() async {
    _chatSocket?.disconnect();
    for (final cb in _onLogout) { cb(); }
    await _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void updateUser(UserModel user) {
    emit(state.copyWith(user: user));
  }
}
