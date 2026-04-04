import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/storage_service.dart';
import '../models/ai_assistant_models.dart';
import '../repositories/student_ai_assistant_repository.dart';
import 'ai_assistant_state.dart';

export 'ai_assistant_state.dart';

class AiAssistantCubit extends Cubit<AiAssistantState> {
  final StudentAiAssistantRepository _repository;
  final StorageService _storage;
  static const String _learningPathOverridesKey =
      'student_ai_learning_path_overrides';

  AiAssistantCubit(this._repository, this._storage)
    : super(const AiAssistantState());

  Future<void> loadAssistantData({bool suppressError = false}) async {
    emit(state.copyWith(status: AiAssistantStatus.loading));
    try {
      final data = await _repository.fetchAssistantData();
      final merged = await _withPersistedLearningPath(data);
      emit(AiAssistantState(status: AiAssistantStatus.loaded, data: merged));
    } catch (e) {
      if (suppressError) {
        emit(
          const AiAssistantState(
            status: AiAssistantStatus.loaded,
            data: AiAssistantData(
              learningPath: [],
              resources: [],
              insights: [],
            ),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AiAssistantStatus.error,
            errorMessage: 'Unable to load AI assistant content right now: $e',
          ),
        );
      }
    }
  }

  Future<void> toggleLearningPathBookmark(LearningPathItemModel item) async {
    final current = state.data;
    if (current == null) return;

    final updatedPath = current.learningPath
        .map(
          (it) => _sameLearningPathItem(it, item)
              ? it.copyWith(isBookmarked: !it.isBookmarked)
              : it,
        )
        .toList();

    final updatedData = AiAssistantData(
      learningPath: updatedPath,
      resources: current.resources,
      insights: current.insights,
    );
    emit(state.copyWith(data: updatedData));
    await _saveLearningPathOverrides(updatedPath);
  }

  Future<void> markLearningPathComplete(LearningPathItemModel item) async {
    final current = state.data;
    if (current == null) return;

    final updatedPath = current.learningPath
        .map(
          (it) => _sameLearningPathItem(it, item)
              ? it.copyWith(progress: 1.0, isActive: false)
              : it,
        )
        .toList();

    final updatedData = AiAssistantData(
      learningPath: updatedPath,
      resources: current.resources,
      insights: current.insights,
    );
    emit(state.copyWith(data: updatedData));
    await _saveLearningPathOverrides(updatedPath);
  }

  Future<AiAssistantData> _withPersistedLearningPath(
    AiAssistantData data,
  ) async {
    final overrides = _readLearningPathOverrides();
    if (overrides.isEmpty) return data;

    final mergedPath = data.learningPath.map((item) {
      final raw = overrides[_learningPathKey(item)];
      if (raw is! Map<String, dynamic>) return item;

      final progress = raw['progress'];
      final isActive = raw['isActive'];
      final isBookmarked = raw['isBookmarked'];

      return item.copyWith(
        progress: progress is num ? progress.toDouble() : item.progress,
        isActive: isActive is bool ? isActive : item.isActive,
        isBookmarked: isBookmarked is bool ? isBookmarked : item.isBookmarked,
      );
    }).toList();

    return AiAssistantData(
      learningPath: mergedPath,
      resources: data.resources,
      insights: data.insights,
    );
  }

  Map<String, dynamic> _readLearningPathOverrides() {
    final raw = _storage.getString(_learningPathOverridesKey);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return const {};
    } catch (_) {
      return const {};
    }
  }

  Future<void> _saveLearningPathOverrides(
    List<LearningPathItemModel> items,
  ) async {
    final map = <String, dynamic>{
      for (final item in items)
        _learningPathKey(item): {
          'progress': item.progress,
          'isActive': item.isActive,
          'isBookmarked': item.isBookmarked,
        },
    };
    await _storage.setString(_learningPathOverridesKey, jsonEncode(map));
  }

  String _learningPathKey(LearningPathItemModel item) {
    return '${item.step}|${item.subject}|${item.title}'.toLowerCase();
  }

  bool _sameLearningPathItem(
    LearningPathItemModel left,
    LearningPathItemModel right,
  ) {
    return _learningPathKey(left) == _learningPathKey(right);
  }
}
