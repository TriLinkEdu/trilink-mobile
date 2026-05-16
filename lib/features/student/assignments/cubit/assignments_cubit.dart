import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/assignment_model.dart';
import '../repositories/student_assignments_repository.dart';
import 'assignments_state.dart';

export 'assignments_state.dart';

class AssignmentsCubit extends Cubit<AssignmentsState> {
  final StudentAssignmentsRepository _repository;
  DateTime? _lastLoadedAt;

  /// Timestamp of the most recent successful network refresh, or null if data
  /// has never loaded from the network in this session.
  DateTime? get lastLoadedAt => _lastLoadedAt;

  static const Duration _ttl = Duration(minutes: 10);

  AssignmentsCubit(this._repository) : super(const AssignmentsState());

  // ── Loading ───────────────────────────────────────────────────────────────

  Future<void> loadIfNeeded() async {
    if (state.status == AssignmentsStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }

    final cached = _repository.getCached();
    if (cached != null) {
      if (state.status != AssignmentsStatus.loaded) {
        emit(AssignmentsState(
          status: AssignmentsStatus.loaded,
          assignments: cached,
          activeFilter: state.activeFilter,
        ));
      }
      unawaited(_silentRefresh());
      return;
    }

    await loadAssignments();
  }

  Future<void> loadAssignments() async {
    emit(state.copyWith(status: AssignmentsStatus.loading));
    try {
      final assignments = await _repository.fetchAssignments();
      emit(AssignmentsState(
        status: AssignmentsStatus.loaded,
        assignments: assignments,
        activeFilter: state.activeFilter,
      ));
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      final msg = e.toString();
      debugPrint('[AssignmentsCubit] loadAssignments failed: $msg');
      emit(state.copyWith(
        status: AssignmentsStatus.error,
        errorMessage: msg.contains('ApiException')
            ? msg.replaceFirst('ApiException', 'Error')
            : 'Unable to load assignments. Please try again.',
      ));
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final assignments = await _repository.fetchAssignments();
      if (!isClosed) {
        emit(AssignmentsState(
          status: AssignmentsStatus.loaded,
          assignments: assignments,
          activeFilter: state.activeFilter,
        ));
        _lastLoadedAt = DateTime.now();
      }
    } catch (_) {}
  }

  /// Force-bust cache and reload fresh data from the network.
  Future<void> refresh() async {
    emit(state.copyWith(status: AssignmentsStatus.loading));
    try {
      final assignments = await _repository.refresh();
      emit(AssignmentsState(
        status: AssignmentsStatus.loaded,
        assignments: assignments,
        activeFilter: state.activeFilter,
      ));
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(state.copyWith(
        status: AssignmentsStatus.error,
        errorMessage: 'Unable to refresh assignments. Please try again.',
      ));
    }
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  void filterByStatus(AssignmentStatus? status) {
    emit(state.copyWith(
      activeFilter: status,
      clearFilter: status == null,
    ));
  }

  // ── Submission ────────────────────────────────────────────────────────────

  Future<bool> submitAssignment(String id, String content) async {
    return _submit(id, content);
  }

  Future<bool> submitAssignmentWithFile(
    String id,
    String content, {
    String? filePath,
  }) async {
    return _submit(id, content, filePath: filePath);
  }

  Future<bool> _submit(
    String id,
    String content, {
    String? filePath,
  }) async {
    if (content.trim().isEmpty) return false;
    emit(state.copyWith(isSubmitting: true));
    try {
      await _repository.submitAssignmentWithFile(id, content, filePath: filePath);
      // Reload to get the updated submission status from the server
      final assignments = await _repository.fetchAssignments();
      emit(AssignmentsState(
        status: AssignmentsStatus.loaded,
        assignments: assignments,
        activeFilter: state.activeFilter,
        isSubmitting: false,
      ));
      _lastLoadedAt = DateTime.now();
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Submission failed. Please check your connection and try again.',
      ));
      return false;
    }
  }
}
