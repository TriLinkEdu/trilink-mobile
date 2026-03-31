import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_dashboard_repository.dart';
import 'dashboard_state.dart';

export 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final StudentDashboardRepository _repository;

  DashboardCubit(this._repository) : super(const DashboardState());

  Future<void> loadDashboard() async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final data = await _repository.fetchDashboardData();
      emit(DashboardState(status: DashboardStatus.loaded, data: data));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
