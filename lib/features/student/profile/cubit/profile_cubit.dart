import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/user_model.dart';
import '../repositories/student_profile_repository.dart';
import 'profile_state.dart';

export 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final StudentProfileRepository _repository;

  ProfileCubit(this._repository) : super(const ProfileState());

  void setUser(UserModel? user) {
    emit(ProfileState(status: ProfileStatus.loaded, user: user));
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final updated = await _repository.updateProfile(
        name: name,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      emit(state.copyWith(user: updated));
    } catch (e) {
      rethrow;
    }
  }
}
