import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/chat_socket_service.dart';
import '../models/chat_models.dart';
import '../repositories/student_chat_repository.dart';
import 'chat_conversation_state.dart';

export 'chat_conversation_state.dart';

class ChatConversationCubit extends Cubit<ChatConversationState> {
  final StudentChatRepository _repository;
  final ChatSocketService? _socket;
  final String conversationId;
  final String? _currentUserId;
  DateTime? _lastLoadedAt;

  static const Duration _ttl = Duration(seconds: 10);

  ChatConversationCubit(
    this._repository,
    this.conversationId, {
    ChatSocketService? socketService,
    String? currentUserId,
  })  : _socket = socketService,
        _currentUserId = currentUserId,
        super(ChatConversationState(
          messages: _repository.getCachedMessages(conversationId) ?? const [],
          status: _repository.getCachedMessages(conversationId) != null 
              ? ConversationStatus.loaded 
              : ConversationStatus.initial,
        )) {
    _subscribeSocket();
  }

  void _subscribeSocket() {
    final socket = _socket;
    if (socket == null) return;
    socket.connect().then((_) {
      socket.joinConversation(conversationId);
      socket.onMessage(conversationId, injectMessage);
    });
  }

  @override
  Future<void> close() {
    final socket = _socket;
    if (socket != null) {
      socket.offMessage(conversationId, injectMessage);
      socket.leaveConversation(conversationId);
    }
    return super.close();
  }

  void markLastRead() {
    final last = state.messages.isNotEmpty ? state.messages.last : null;
    if (last == null || last.id.isEmpty) return;
    _socket?.markRead(conversationId, last.id);
    _repository.markRead(conversationId, last.id);
  }

  Future<void> loadIfNeeded() async {
    if (state.status == ConversationStatus.loaded &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _ttl) {
      return;
    }
    await Future.wait([loadMessages(), loadMembers()]);
  }

  Future<void> loadMessages({bool showLoading = true}) async {
    if (showLoading && state.messages.isEmpty) {
      emit(state.copyWith(status: ConversationStatus.loading));
    }
    try {
      final messages = await _repository.fetchMessages(conversationId, limit: 50);
      emit(
        ChatConversationState(
          status: ConversationStatus.loaded,
          messages: messages,
          hasReachedMax: messages.length < 50,
        ),
      );
      _lastLoadedAt = DateTime.now();
      markLastRead();
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

    // Use oldest held message ID as cursor for the backend's before-based pagination.
    final oldestId = state.messages.isNotEmpty ? state.messages.first.id : null;
    if (oldestId == null || oldestId.isEmpty) return;

    try {
      final newMessages = await _repository.fetchMessages(
        conversationId,
        before: oldestId,
        limit: 50,
      );

      emit(
        state.copyWith(
          status: ConversationStatus.loaded,
          messages: [...newMessages, ...state.messages],
          hasReachedMax: newMessages.length < 50,
        ),
      );
    } catch (_) {
      // Ignore pagination errors to keep existing messages visible.
    }
  }

  void injectMessage(ChatMessageModel message) {
    final already = state.messages.any((m) => m.id == message.id);
    if (already) return;
    emit(
      state.copyWith(
        status: ConversationStatus.loaded,
        messages: [...state.messages, message],
      ),
    );
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
    // 1. Create a temporary pending message shown immediately
    final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = ChatMessageModel(
      id: tempId,
      senderId: _currentUserId ?? '',
      senderName: 'You',
      content: text,
      timestamp: DateTime.now(),
      isRead: true,
      isPending: true,
    );
    emit(state.copyWith(messages: [...state.messages, optimistic]));

    try {
      final sentMessage = await _repository.sendMessage(conversationId, text);
      // 2. Replace the pending bubble with the real confirmed message
      final updated = state.messages
          .where((m) => m.id != tempId)
          .toList()
        ..add(sentMessage);
      emit(state.copyWith(status: ConversationStatus.loaded, messages: updated));
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      // 3. Mark the bubble as failed so user sees a retry option
      final failed = state.messages.map((m) {
        if (m.id == tempId) {
          return ChatMessageModel(
            id: tempId,
            senderId: m.senderId,
            senderName: m.senderName,
            content: m.content,
            timestamp: m.timestamp,
            isRead: m.isRead,
            isPending: false,
            isFailed: true,
          );
        }
        return m;
      }).toList();
      emit(state.copyWith(messages: failed));
      rethrow;
    }
  }

  Future<void> retrySendMessage(String tempId, String text) async {
    // Remove the failed message and resend
    final without = state.messages.where((m) => m.id != tempId).toList();
    emit(state.copyWith(messages: without));
    await sendMessage(text);
  }

  Future<void> sendImageMessage(String imagePath) async {
    final tempId = 'pending_img_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = ChatMessageModel(
      id: tempId,
      senderId: _currentUserId ?? '',
      senderName: 'You',
      content: '',
      timestamp: DateTime.now(),
      isRead: true,
      type: MessageType.image,
      isPending: true,
    );
    emit(state.copyWith(messages: [...state.messages, optimistic]));

    try {
      final sentMessage = await _repository.sendImageMessage(conversationId, imagePath);
      final updated = state.messages
          .where((m) => m.id != tempId)
          .toList()
        ..add(sentMessage);
      emit(state.copyWith(status: ConversationStatus.loaded, messages: updated));
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      final failed = state.messages.map((m) {
        if (m.id == tempId) {
          return ChatMessageModel(
            id: tempId,
            senderId: m.senderId,
            senderName: m.senderName,
            content: '[Image failed to send]',
            timestamp: m.timestamp,
            isRead: m.isRead,
            isPending: false,
            isFailed: true,
          );
        }
        return m;
      }).toList();
      emit(state.copyWith(messages: failed));
      rethrow;
    }
  }

  Future<void> sendFileMessage(String filePath) async {
    final tempId = 'pending_file_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = ChatMessageModel(
      id: tempId,
      senderId: _currentUserId ?? '',
      senderName: 'You',
      content: '',
      timestamp: DateTime.now(),
      isRead: true,
      type: MessageType.file,
      isPending: true,
    );
    emit(state.copyWith(messages: [...state.messages, optimistic]));

    try {
      final sentMessage = await _repository.sendFileMessage(conversationId, filePath);
      final updated = state.messages
          .where((m) => m.id != tempId)
          .toList()
        ..add(sentMessage);
      emit(state.copyWith(status: ConversationStatus.loaded, messages: updated));
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      final failed = state.messages.map((m) {
        if (m.id == tempId) {
          return ChatMessageModel(
            id: tempId,
            senderId: m.senderId,
            senderName: m.senderName,
            content: '[File failed to send]',
            timestamp: m.timestamp,
            isRead: m.isRead,
            isPending: false,
            isFailed: true,
          );
        }
        return m;
      }).toList();
      emit(state.copyWith(messages: failed));
      rethrow;
    }
  }
