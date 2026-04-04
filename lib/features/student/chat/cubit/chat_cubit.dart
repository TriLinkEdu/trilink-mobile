import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/chat_models.dart';
import '../repositories/student_chat_repository.dart';
import 'chat_state.dart';

export 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final StudentChatRepository _repository;

  ChatCubit(this._repository) : super(const ChatState());

  Future<void> loadConversations() async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final conversations = await _repository.fetchConversations();
      emit(ChatState(status: ChatStatus.loaded, conversations: conversations));
    } catch (e) {
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Unable to load conversations: $e',
        ),
      );
    }
  }

  Future<ChatConversationModel?> createConversation({
    required String title,
    required List<String> participantIds,
    required bool isGroup,
  }) async {
    try {
      final conversation = await _repository.createConversation(
        title: title,
        participantIds: participantIds,
        isGroup: isGroup,
      );
      await loadConversations();
      return conversation;
    } catch (e) {
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Unable to create conversation: $e',
        ),
      );
      return null;
    }
  }
}
