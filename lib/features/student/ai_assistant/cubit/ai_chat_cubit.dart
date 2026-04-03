import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/ai_assistant_models.dart';
import '../repositories/student_ai_assistant_repository.dart';

part 'ai_chat_state.dart';

class AiChatCubit extends Cubit<AiChatState> {
  final StudentAiAssistantRepository _repository;

  AiChatCubit(this._repository) : super(const AiChatState());

  Future<void> sendMessage(String text) async {
    final userMessage = AiChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage],
      isResponding: true,
    ));

    try {
      final response = await _repository.getAiResponse(text);
      final aiMessage = AiChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        messages: [...state.messages, aiMessage],
        isResponding: false,
      ));
    } catch (_) {
      final errorMessage = AiChatMessage(
        text: 'Sorry, I couldn\'t process that. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        messages: [...state.messages, errorMessage],
        isResponding: false,
      ));
    }
  }
}
