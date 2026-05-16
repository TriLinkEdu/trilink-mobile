import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_grades_repository.dart';
import 'grades_state.dart';

export 'grades_state.dart';

class GradesCubit extends Cubit<GradesState> {
  final StudentGradesRepository _repository;
  DateTime? _lastLoadedAt;

  /// Timestamp of the most recent successful network refresh, or null if data
  /// has never loaded from the network in this session.
  DateTime? get lastLoadedAt => _lastLoadedAt;

  static const Duration _ttl = Duration(minutes: 30);

  GradesCubit(this._repository) : super(const GradesState());

  // ── Loading ───────────────────────────────────────────────────────────────

  Future<void> loadIfNeeded({String? term}) async {
    final targetTerm = term ?? state.selectedTerm;
    // Fresh in-memory cubit state — skip.
    if (state.status == GradesStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl &&
        (targetTerm.isEmpty || targetTerm == state.selectedTerm)) return;

    // SWR: if repo has cached grades, render them immediately.
    final cached = _repository.getCached();
    if (cached != null && state.status != GradesStatus.loaded) {
      final filtered = targetTerm.isEmpty
          ? cached
          : cached.where((g) => g.term == targetTerm).toList();
      final terms = _distinctTerms(cached);
      final resolved = _resolveTerm(
        requested: targetTerm.isEmpty ? null : targetTerm,
        current: state.selectedTerm,
        available: terms,
      );
      emit(state.copyWith(
        status: GradesStatus.loaded,
        grades: filtered,
        selectedTerm: resolved,
        availableTerms: terms,
      ));
    }
    unawaited(_silentRefresh(targetTerm: targetTerm));
  }

  Future<void> _silentRefresh({String? targetTerm}) async {
    try {
      final results = await Future.wait([
        _repository.fetchAvailableTerms(),
        _repository.fetchGrades(),
      ]);
      if (isClosed) return;
      final availableTerms = results[0] as List<String>;
      final allGrades = results[1] as List<dynamic>;
      final resolved = _resolveTerm(
        requested: targetTerm,
        current: state.selectedTerm,
        available: availableTerms,
      );
      final filtered = resolved.isEmpty
          ? List.from(allGrades)
          : allGrades.where((g) => g.term == resolved).toList();
      emit(state.copyWith(
        status: GradesStatus.loaded,
        grades: List.from(filtered),
        selectedTerm: resolved,
        availableTerms: availableTerms,
      ));
      _lastLoadedAt = DateTime.now();
    } catch (_) {}
  }

  List<String> _distinctTerms(List allGrades) {
    final seen = <String>{};
    final terms = <String>[];
    for (final g in allGrades) {
      final t = (g as dynamic).term as String?;
      if (t != null && seen.add(t)) terms.add(t);
    }
    return terms;
  }

  Future<void> loadGrades({String? term}) async {
    emit(state.copyWith(status: GradesStatus.loading));
    try {
      // Fetch available terms and full grade list in parallel.
      final results = await Future.wait([
        _repository.fetchAvailableTerms(),
        _repository.fetchGrades(),
      ]);

      final availableTerms = results[0] as List<String>;
      final allGrades = results[1] as List<dynamic>;

      // Default to the most recent term when none is selected yet.
      final resolvedTerm = _resolveTerm(
        requested: term,
        current: state.selectedTerm,
        available: availableTerms,
      );

      // Filter locally so we don't need an extra network call on term switch.
      final filtered = resolvedTerm.isEmpty
          ? List.from(allGrades)
          : allGrades.where((g) => g.term == resolvedTerm).toList();

      emit(state.copyWith(
        status: GradesStatus.loaded,
        grades: List.from(filtered),
        selectedTerm: resolvedTerm,
        availableTerms: availableTerms,
      ));
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(state.copyWith(
        status: GradesStatus.error,
        errorMessage: 'Unable to load grades. Please try again.',
      ));
    }
  }

  void switchTerm(String term) {
    // Filter the already-loaded grades locally — no network call needed.
    if (state.status != GradesStatus.loaded) {
      loadGrades(term: term);
      return;
    }
    // Re-load to get the filtered view; data is cached so it is instant.
    loadGrades(term: term);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Resolve which term to display:
  /// 1. An explicitly requested term (e.g. user tapped the dropdown).
  /// 2. The currently selected term if already set.
  /// 3. The most recent available term from live data.
  /// 4. Empty string if no data at all.
  String _resolveTerm({
    required String? requested,
    required String current,
    required List<String> available,
  }) {
    if (requested != null && requested.isNotEmpty) return requested;
    if (current.isNotEmpty && available.contains(current)) return current;
    return available.isNotEmpty ? available.first : '';
  }
}
