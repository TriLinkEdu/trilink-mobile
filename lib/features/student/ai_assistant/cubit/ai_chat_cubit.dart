import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/ai_assistant_models.dart';
import '../repositories/student_ai_assistant_repository.dart';

part 'ai_chat_state.dart';

class AiChatCubit extends Cubit<AiChatState> {
  final StudentAiAssistantRepository _repository;

  AiChatCubit(this._repository) : super(const AiChatState());

  /// Load persisted chat history from the backend (called once on screen init).
  Future<void> loadHistory() async {
    if (state.historyLoaded || state.isLoadingHistory) return;
    emit(state.copyWith(isLoadingHistory: true));
    try {
      final history = await _repository.fetchChatHistory();
      emit(state.copyWith(
        messages: [...history, ...state.messages],
        isLoadingHistory: false,
        historyLoaded: true,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingHistory: false, historyLoaded: true));
    }
  }

  Future<void> sendMessage(String text) async {
    final userMessage = AiChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        isResponding: true,
        chatStage: 'Checking your question…',
      ),
    );

    // Simulate visible pipeline stages so the wait feels active.
    final stage2 = Timer(const Duration(seconds: 2), () {
      if (state.isResponding) emit(state.copyWith(chatStage: 'Searching textbooks…'));
    });
    final stage3 = Timer(const Duration(seconds: 5), () {
      if (state.isResponding) emit(state.copyWith(chatStage: 'Writing your answer…'));
    });

    try {
      final aiMessage = await _repository.getAiResponse(text);
      stage2.cancel();
      stage3.cancel();
      emit(
        state.copyWith(
          messages: [...state.messages, aiMessage],
          isResponding: false,
          clearChatStage: true,
        ),
      );
    } catch (e) {
      stage2.cancel();
      stage3.cancel();
      final friendly = e.toString().contains('not configured')
          ? 'The AI assistant is not available right now. Please try again later.'
          : 'Sorry, I couldn\'t reach the assistant. Tap retry to try again.';
      final errorMessage = AiChatMessage(
        text: friendly,
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );

      emit(
        state.copyWith(
          messages: [...state.messages, errorMessage],
          isResponding: false,
          clearChatStage: true,
        ),
      );
    }
  }

  /// Retry the last user message after an error. Removes the trailing error
  /// bubble (and its preceding user message) before re-sending.
  Future<void> retryLast() async {
    if (state.isResponding) return;
    final messages = [...state.messages];
    if (messages.isEmpty || !messages.last.isError) return;

    // Drop the error bubble.
    messages.removeLast();
    // Find and drop the most recent user message to re-send it.
    String? lastUserText;
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isUser) {
        lastUserText = messages[i].text;
        messages.removeAt(i);
        break;
      }
    }
    if (lastUserText == null) return;

    emit(state.copyWith(messages: messages));
    await sendMessage(lastUserText);
  }
}
