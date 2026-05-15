import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/models/student_goal_model.dart';
import '../repositories/student_analytics_repository.dart';
import 'yearly_planner_state.dart';

class YearlyPlannerCubit extends Cubit<YearlyPlannerState> {
  final ApiClient _apiClient;
  final StorageService _storageService;

  YearlyPlannerCubit({
    StudentAnalyticsRepository? analyticsRepository, // Kept for backwards compatibility if needed, but unused
    ApiClient? apiClient,
    StorageService? storageService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storageService = storageService ?? StorageService(),
        super(const YearlyPlannerState());

  Future<void> loadPlanner() async {
    if (state.status == YearlyPlannerStatus.loading) return;

    emit(state.copyWith(status: YearlyPlannerStatus.loading, clearError: true));

    try {
      final user = await _storageService.getUser();
      final studentId = (user?['id'] ?? '').toString();

      if (studentId.isEmpty) {
        throw Exception('User session not found');
      }

      final data = await _safeGetMap('/analytics/student/yearly-planner');

      final academicYear = data['academicYear']?.toString() ?? 'N/A';
      final overallScore = _asDouble(data['overallScore'], fallback: 0.0);
      final attendanceRate = _asDouble(data['attendanceRate'], fallback: 0.0);
      final totalXp = _asInt(data['totalXp'], fallback: 0);
      final goalsCompleted = _asInt(data['goalsCompleted'], fallback: 0);
      final goalsTotal = _asInt(data['goalsTotal'], fallback: 0);
      final currentTermIndex = _asInt(data['currentTermIndex'], fallback: 0);

      final rawTerms = _readList(data['terms']);
      final terms = rawTerms.map((t) {
        if (t is! Map) return null;
        return TermProgress(
          id: t['id']?.toString() ?? '',
          name: t['name']?.toString() ?? '',
          dateRange: t['dateRange']?.toString() ?? '',
          avgScore: _asDouble(t['avgScore'], fallback: 0.0),
          attendanceRate: _asDouble(t['attendanceRate'], fallback: 0.0),
          goalsHit: _asInt(t['goalsHit'], fallback: 0),
          goalsTotal: _asInt(t['goalsTotal'], fallback: 0),
        );
      }).whereType<TermProgress>().toList();

      final rawGoals = _readList(data['activeGoals']);
      final activeGoals = rawGoals.map((g) {
        if (g is! Map) return null;
        return StudentGoalModel(
          id: g['id']?.toString() ?? '',
          studentId: g['studentId']?.toString() ?? '',
          goalText: g['goalText']?.toString() ?? '',
          targetDate: g['targetDate'] != null ? DateTime.tryParse(g['targetDate'].toString()) : null,
          isAchieved: g['isAchieved'] == true,
          createdAt: g['createdAt'] != null ? DateTime.tryParse(g['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
        );
      }).whereType<StudentGoalModel>().toList();

      emit(
        state.copyWith(
          status: YearlyPlannerStatus.loaded,
          academicYear: academicYear,
          overallScore: overallScore,
          attendanceRate: attendanceRate,
          totalXp: totalXp,
          goalsCompleted: goalsCompleted,
          goalsTotal: goalsTotal,
          terms: terms,
          currentTermIndex: currentTermIndex,
          activeGoals: activeGoals,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: YearlyPlannerStatus.error,
          errorMessage: 'Failed to load planner data: $e',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _safeGetMap(String path) async {
    try {
      return await _apiClient.get(path);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  double _asDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  List<dynamic> _readList(dynamic value) {
    if (value is List) return value;
    return const [];
  }
}
