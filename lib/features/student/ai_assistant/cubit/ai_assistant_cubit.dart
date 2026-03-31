import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/ai_assistant_models.dart';
import '../repositories/student_ai_assistant_repository.dart';
import 'ai_assistant_state.dart';

export 'ai_assistant_state.dart';

class AiAssistantCubit extends Cubit<AiAssistantState> {
  final StudentAiAssistantRepository _repository;

  AiAssistantCubit(this._repository) : super(const AiAssistantState());

  Future<void> loadAssistantData({bool suppressError = false}) async {
    emit(state.copyWith(status: AiAssistantStatus.loading));
    try {
      final data = await _repository.fetchAssistantData();
      emit(AiAssistantState(
        status: AiAssistantStatus.loaded,
        data: data,
      ));
    } catch (_) {
      if (suppressError) {
        emit(const AiAssistantState(
          status: AiAssistantStatus.loaded,
          data: AiAssistantData(
            learningPath: [],
            resources: [],
            insights: [],
          ),
        ));
      } else {
        emit(state.copyWith(
          status: AiAssistantStatus.error,
          errorMessage: 'Unable to load AI assistant content right now.',
        ));
      }
    }
  }
}
