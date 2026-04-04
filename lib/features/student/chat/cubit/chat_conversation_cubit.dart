import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_chat_repository.dart';
import 'chat_conversation_state.dart';

export 'chat_conversation_state.dart';

class ChatConversationCubit extends Cubit<ChatConversationState> {
  final StudentChatRepository _repository;
  final String conversationId;

  ChatConversationCubit(this._repository, this.conversationId)
    : super(const ChatConversationState());

  Future<void> loadMessages({bool showLoading = true}) async {
    if (showLoading) {
      emit(state.copyWith(status: ConversationStatus.loading));
    }
    try {
      final messages = await _repository.fetchMessages(conversationId);
      emit(
        ChatConversationState(
          status: ConversationStatus.loaded,
          messages: messages,
        ),
      );
    } catch (e) {
      if (showLoading) {
        emit(
          state.copyWith(
            status: ConversationStatus.error,
            errorMessage: 'Unable to load messages.',
          ),
        );
      }
    }
  }

  Future<void> sendMessage(String text) async {
    try {
      final sentMessage = await _repository.sendMessage(conversationId, text);
      emit(
        state.copyWith(
          status: ConversationStatus.loaded,
          messages: [...state.messages, sentMessage],
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Unable to send message.'));
      rethrow;
    }
  }
}
