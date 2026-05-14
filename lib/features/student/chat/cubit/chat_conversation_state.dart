import 'package:equatable/equatable.dart';
import '../models/chat_models.dart';

enum ConversationStatus { initial, loading, loaded, error }

class ChatConversationState extends Equatable {
  final ConversationStatus status;
  final List<ChatMessageModel> messages;
  final List<ChatMemberModel> members;
  final bool membersLoading;
  final String? errorMessage;
  final bool hasReachedMax;

  const ChatConversationState({
    this.status = ConversationStatus.initial,
    this.messages = const [],
    this.members = const [],
    this.membersLoading = false,
    this.errorMessage,
    this.hasReachedMax = false,
  });

  ChatConversationState copyWith({
    ConversationStatus? status,
    List<ChatMessageModel>? messages,
    List<ChatMemberModel>? members,
    bool? membersLoading,
    String? errorMessage,
    bool? hasReachedMax,
  }) {
    return ChatConversationState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      members: members ?? this.members,
      membersLoading: membersLoading ?? this.membersLoading,
      errorMessage: errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [status, messages, members, membersLoading, errorMessage, hasReachedMax];
}
