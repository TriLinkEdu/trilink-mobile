import 'dart:async';
import 'dart:math';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

/// Singleton WebSocket service using Socket.IO.
/// Manages the connection lifecycle, room membership, and exposes
/// typed broadcast streams for each server-emitted event.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _connected = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  String? _token;
  Timer? _reconnectTimer;

  // ── Broadcast StreamControllers ──────────────────────────────────────────

  final _messageNewCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _conversationUpdateCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _presenceUpdateCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _typingUpdateCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _readUpdateCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionErrorCtrl = StreamController<String>.broadcast();

  // ── Public streams ────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> get messageNewStream =>
      _messageNewCtrl.stream;
  Stream<Map<String, dynamic>> get conversationUpdateStream =>
      _conversationUpdateCtrl.stream;
  Stream<Map<String, dynamic>> get presenceUpdateStream =>
      _presenceUpdateCtrl.stream;
  Stream<Map<String, dynamic>> get typingUpdateStream =>
      _typingUpdateCtrl.stream;
  Stream<Map<String, dynamic>> get readUpdateStream =>
      _readUpdateCtrl.stream;
  Stream<String> get connectionErrorStream => _connectionErrorCtrl.stream;

  bool get isConnected => _connected;

  // ── Connection ────────────────────────────────────────────────────────────

  /// Derive the Socket.IO base URL by stripping the /api suffix.
  String get _wsUrl {
    final base = ApiConstants.baseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  Future<void> connect(String token) async {
    _token = token;
    _reconnectTimer?.cancel();

    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    _socket = IO.io(
      _wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      _retryCount = 0;
      _reconnectTimer?.cancel();
      // Authenticate the session
      _socket!.emit('auth:hello', {'token': token});
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      _scheduleReconnect();
    });

    _socket!.onConnectError((_) {
      _connected = false;
      _scheduleReconnect();
    });

    // ── Server → Client events ──────────────────────────────────────────────

    _socket!.on('message:new', (data) {
      _emit(_messageNewCtrl, data);
    });

    _socket!.on('conversation:update', (data) {
      _emit(_conversationUpdateCtrl, data);
    });

    _socket!.on('presence:update', (data) {
      _emit(_presenceUpdateCtrl, data);
    });

    _socket!.on('typing:update', (data) {
      _emit(_typingUpdateCtrl, data);
    });

    _socket!.on('read:update', (data) {
      _emit(_readUpdateCtrl, data);
    });

    _socket!.connect();
  }

  void _scheduleReconnect() {
    if (_retryCount >= _maxRetries) {
      _connectionErrorCtrl.add(
        'Real-time connection failed after $_maxRetries attempts.',
      );
      return;
    }
    final delay = Duration(milliseconds: (pow(2, _retryCount) * 1000).toInt());
    _retryCount++;
    _reconnectTimer = Timer(delay, () {
      if (_token != null) connect(_token!);
    });
  }

  void _emit(
    StreamController<Map<String, dynamic>> ctrl,
    dynamic data,
  ) {
    if (data is Map<String, dynamic>) {
      ctrl.add(data);
    } else if (data is Map) {
      ctrl.add(Map<String, dynamic>.from(data));
    }
  }

  // ── Room management ───────────────────────────────────────────────────────

  void joinConversation(String conversationId) {
    _socket?.emit('conversation:join', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('conversation:leave', {'conversationId': conversationId});
  }

  // ── Presence ──────────────────────────────────────────────────────────────

  void setPresence(String status) {
    _socket?.emit('presence:set', {'status': status});
  }

  // ── Typing ────────────────────────────────────────────────────────────────

  void sendTyping(String conversationId, bool isTyping) {
    _socket?.emit('typing:update', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  // ── Read receipts ─────────────────────────────────────────────────────────

  void sendReadUpdate(String conversationId, String messageId) {
    _socket?.emit('read:update', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.dispose();
    _socket = null;
    _connected = false;
    _retryCount = 0;
    _token = null;
  }
}
