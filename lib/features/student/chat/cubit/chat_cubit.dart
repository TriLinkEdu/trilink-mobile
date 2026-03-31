import 'package:flutter_bloc/flutter_bloc.dart';
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
    } catch (_) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: 'Unable to load conversations.',
      ));
    }
  }
}
