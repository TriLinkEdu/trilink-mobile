part of 'ai_chat_cubit.dart';

class AiChatState extends Equatable {
  final List<AiChatMessage> messages;
  final bool isResponding;
  final bool isLoadingHistory;
  final bool historyLoaded;
  final String? chatStage;

  const AiChatState({
    this.messages = const [],
    this.isResponding = false,
    this.isLoadingHistory = false,
    this.historyLoaded = false,
    this.chatStage,
  });

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    bool? isResponding,
    bool? isLoadingHistory,
    bool? historyLoaded,
    String? chatStage,
    bool clearChatStage = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isResponding: isResponding ?? this.isResponding,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      historyLoaded: historyLoaded ?? this.historyLoaded,
      chatStage: clearChatStage ? null : (chatStage ?? this.chatStage),
    );
  }

  @override
  List<Object?> get props =>
      [messages, isResponding, isLoadingHistory, historyLoaded, chatStage];
}
