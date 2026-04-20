import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/chat_models.dart';
import '../repositories/student_chat_repository.dart';
import 'chat_state.dart';

export 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final StudentChatRepository _repository;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 20);

  ChatCubit(this._repository) : super(const ChatState());

  Future<void> loadIfNeeded() async {
    if (state.status == ChatStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await loadConversations();
  }

  Future<void> loadConversations() async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final conversations = await _repository.fetchConversations();
      emit(ChatState(status: ChatStatus.loaded, conversations: conversations));
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Unable to load conversations.',
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
          errorMessage: 'Unable to create conversation.',
        ),
      );
      return null;
    }
  }
}
