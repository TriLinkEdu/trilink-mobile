import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';
import '../services/storage_service.dart';
import '../../features/student/chat/models/chat_models.dart';

typedef MessageHandler = void Function(ChatMessageModel message);
typedef ConversationUpdateHandler = void Function(Map<String, dynamic> raw);
typedef TypingHandler = void Function(String conversationId, String userId, bool isTyping);

class ChatSocketService {
  final StorageService _storage;

  io.Socket? _socket;

  final Map<String, Set<MessageHandler>> _messageListeners = {};
  final Set<ConversationUpdateHandler> _convUpdateListeners = {};
  final Set<TypingHandler> _typingListeners = {};

  String _currentUserId = '';

  ChatSocketService({required StorageService storageService})
      : _storage = storageService;

  bool get isConnected => _socket?.connected == true;

  // ── Connect / Disconnect ────────────────────────────────────

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final user = await _storage.getUser();
    final token = await _storage.accessToken;
    _currentUserId = (user?['id'] ?? '').toString();

    if (token == null || token.isEmpty) return;

    _socket = io.io(
      ApiConstants.wsBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.on('connect', (_) {
      _socket!.emit('auth:hello', {});
    });

    _socket!.on('message:new', _handleMessageNew);
    _socket!.on('message:edited', _handleMessageNew);
    _socket!.on('message:reaction', _handleMessageNew);
    _socket!.on('conversation:update', _handleConversationUpdate);
    _socket!.on('typing:update', _handleTyping);

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ── Room management ─────────────────────────────────────────

  void joinConversation(String conversationId) {
    _socket?.emit('conversation:join', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('conversation:leave', {'conversationId': conversationId});
  }

  // ── Outgoing events ─────────────────────────────────────────

  void sendTyping(String conversationId, {required bool isTyping}) {
    _socket?.emit('typing:update', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  void markRead(String conversationId, String messageId) {
    _socket?.emit('read:update', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  // ── Subscriptions ───────────────────────────────────────────

  void onMessage(String conversationId, MessageHandler handler) {
    _messageListeners.putIfAbsent(conversationId, () => {}).add(handler);
  }

  void offMessage(String conversationId, MessageHandler handler) {
    _messageListeners[conversationId]?.remove(handler);
  }

  void onConversationUpdate(ConversationUpdateHandler handler) {
    _convUpdateListeners.add(handler);
  }

  void offConversationUpdate(ConversationUpdateHandler handler) {
    _convUpdateListeners.remove(handler);
  }

  void onTyping(TypingHandler handler) {
    _typingListeners.add(handler);
  }

  void offTyping(TypingHandler handler) {
    _typingListeners.remove(handler);
  }

  // ── Internal event handlers ─────────────────────────────────

  void _handleMessageNew(dynamic data) {
    if (data is! Map<String, dynamic>) return;
    final conversationId = (data['conversationId'] ?? '').toString();
    final listeners = _messageListeners[conversationId];
    if (listeners == null || listeners.isEmpty) return;

    try {
      final message = _mapMessage(data);
      for (final handler in List.of(listeners)) {
        handler(message);
      }
    } catch (_) {
      // Malformed payload — ignore.
    }
  }

  void _handleConversationUpdate(dynamic data) {
    if (data is! Map<String, dynamic>) return;
    for (final handler in List.of(_convUpdateListeners)) {
      handler(data);
    }
  }

  void _handleTyping(dynamic data) {
    if (data is! Map<String, dynamic>) return;
    final conversationId = (data['conversationId'] ?? '').toString();
    final userId = (data['userId'] ?? '').toString();
    final isTyping = data['isTyping'] == true;
    for (final handler in List.of(_typingListeners)) {
      handler(conversationId, userId, isTyping);
    }
  }

  // ── Message mapping ─────────────────────────────────────────

  ChatMessageModel _mapMessage(Map<String, dynamic> raw) {
    final senderId = (raw['senderId'] ?? '').toString();
    final senderName = (raw['senderName'] ?? '').toString();
    final mediaFileId = (raw['mediaFileId'] ?? '').toString();
    final mediaType = (raw['mediaType'] ?? '').toString();
    final createdAt =
        DateTime.tryParse((raw['createdAt'] ?? '').toString()) ??
        DateTime.now();

    MessageType type = MessageType.text;
    if (mediaType == 'image') type = MessageType.image;
    if (mediaType == 'video' || mediaType == 'audio' || mediaType == 'file') {
      type = MessageType.file;
    }

    final mediaUrl = mediaFileId.isEmpty
        ? null
        : '${ApiConstants.fileBaseUrl}${ApiConstants.fileDownload(mediaFileId)}';

    return ChatMessageModel(
      id: (raw['id'] ?? '').toString(),
      senderId: senderId,
      senderName:
          senderId == _currentUserId ? 'You' : (senderName.isEmpty ? 'User' : senderName),
      content: (raw['text'] ?? '').toString(),
      timestamp: createdAt,
      isRead: senderId == _currentUserId,
      type: type,
      senderProfileImage: (raw['senderProfileImage'] ?? '').toString().isEmpty
          ? null
          : (raw['senderProfileImage'] as String),
      senderRole: (raw['senderRole'] ?? '').toString().isEmpty
          ? null
          : (raw['senderRole'] as String),
      senderGrade: (raw['senderGrade'] ?? '').toString().isEmpty
          ? null
          : (raw['senderGrade'] as String),
      mediaFileId: mediaFileId.isEmpty ? null : mediaFileId,
      mediaUrl: mediaUrl,
      mediaType: mediaType.isEmpty ? null : mediaType,
      mediaName: (raw['mediaName'] ?? '').toString().isEmpty
          ? null
          : (raw['mediaName'] as String),
      mediaMimeType: (raw['mediaMimeType'] ?? '').toString().isEmpty
          ? null
          : (raw['mediaMimeType'] as String),
      readReceipts: const [],
    );
  }
}
