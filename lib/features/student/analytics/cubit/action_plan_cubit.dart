import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/storage_service.dart';
import '../models/student_growth_models.dart';
import '../repositories/student_analytics_repository.dart';
import 'action_plan_state.dart';

class ActionPlanCubit extends Cubit<ActionPlanState> {
  final StudentAnalyticsRepository _repository;
  final StorageService _storage;
  static const String _actionPlanDoneKey = 'student_growth_action_plan_done';
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 20);

  ActionPlanCubit(this._repository, this._storage)
    : super(const ActionPlanState());

  Future<void> loadIfNeeded() async {
    if (state.status == ActionPlanStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadPlan();
  }

  Future<void> loadPlan() async {
    emit(state.copyWith(status: ActionPlanStatus.loading));
    try {
      final base = await _repository.fetchActionPlan();
      final doneMap = _readDoneMap();
      final merged = base
          .map((it) => it.copyWith(done: doneMap[it.id] ?? it.done))
          .toList();
      emit(
        state.copyWith(
          status: ActionPlanStatus.loaded,
          items: merged,
          errorMessage: null,
        ),
      );
      _lastLoadedAt = DateTime.now();
    } catch (_) {
      emit(
        state.copyWith(
          status: ActionPlanStatus.error,
          errorMessage: 'Unable to load action plan.',
        ),
      );
    }
  }

  Future<void> toggleDone(String itemId) async {
    final updated = state.items
        .map((it) => it.id == itemId ? it.copyWith(done: !it.done) : it)
        .toList();
    emit(state.copyWith(items: updated));
    await _saveDoneMap(updated);
  }

  Map<String, bool> _readDoneMap() {
    final raw = _storage.getString(_actionPlanDoneKey);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const {};
      return decoded.map((k, v) => MapEntry(k, v == true));
    } catch (_) {
      return const {};
    }
  }

  Future<void> _saveDoneMap(List<StudentActionItem> items) async {
    final data = <String, bool>{for (final i in items) i.id: i.done};
    await _storage.setString(_actionPlanDoneKey, jsonEncode(data));
  }
}
