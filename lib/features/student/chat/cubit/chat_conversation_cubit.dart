import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/student_chat_repository.dart';
import 'chat_conversation_state.dart';

export 'chat_conversation_state.dart';

class ChatConversationCubit extends Cubit<ChatConversationState> {
  final StudentChatRepository _repository;
  final String conversationId;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 10);

  ChatConversationCubit(this._repository, this.conversationId)
    : super(const ChatConversationState());

  Future<void> loadIfNeeded() async {
    if (state.status == ConversationStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await Future.wait([loadMessages(), loadMembers()]);
  }

  Future<void> loadMessages({bool showLoading = true}) async {
    if (showLoading) {
      emit(state.copyWith(status: ConversationStatus.loading));
    }
    try {
      final messages = await _repository.fetchMessages(conversationId, offset: 0, limit: 50);
      emit(
        ChatConversationState(
          status: ConversationStatus.loaded,
          messages: messages,
          hasReachedMax: messages.length < 50,
        ),
      );
      _lastLoadedAt = DateTime.now();
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

  Future<void> loadMoreMessages() async {
    if (state.hasReachedMax || state.status == ConversationStatus.loading) return;

    try {
      final newMessages = await _repository.fetchMessages(
        conversationId,
        offset: state.messages.length,
        limit: 50,
      );
      
      emit(
        state.copyWith(
          status: ConversationStatus.loaded,
          messages: [...newMessages, ...state.messages], // new messages are older
          hasReachedMax: newMessages.length < 50,
        ),
      );
    } catch (_) {
      // Ignore errors on pagination to not break the UI
    }
  }

  Future<void> loadMembers() async {
    if (state.membersLoading) return;
    emit(state.copyWith(membersLoading: true));
    try {
      final members = await _repository.fetchConversationMembers(conversationId);
      emit(state.copyWith(members: members, membersLoading: false));
    } catch (e) {
      emit(state.copyWith(membersLoading: false));
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
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Unable to send message.'));
      rethrow;
    }
  }

  Future<void> sendImageMessage(String imagePath) async {
    try {
      final sentMessage = await _repository.sendImageMessage(conversationId, imagePath);
      emit(
        state.copyWith(
          status: ConversationStatus.loaded,
          messages: [...state.messages, sentMessage],
        ),
      );
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Unable to send image.'));
      rethrow;
    }
  }

  Future<void> sendFileMessage(String filePath) async {
    try {
      final sentMessage = await _repository.sendFileMessage(conversationId, filePath);
      emit(
        state.copyWith(
          status: ConversationStatus.loaded,
          messages: [...state.messages, sentMessage],
        ),
      );
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Unable to send file.'));
      rethrow;
    }
  }
}
