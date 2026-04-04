import 'package:equatable/equatable.dart';
import '../models/chat_models.dart';

enum ConversationStatus { initial, loading, loaded, error }

class ChatConversationState extends Equatable {
  final ConversationStatus status;
  final List<ChatMessageModel> messages;
  final String? errorMessage;

  const ChatConversationState({
    this.status = ConversationStatus.initial,
    this.messages = const [],
    this.errorMessage,
  });

  ChatConversationState copyWith({
    ConversationStatus? status,
    List<ChatMessageModel>? messages,
    String? errorMessage,
  }) {
    return ChatConversationState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, messages, errorMessage];
}
