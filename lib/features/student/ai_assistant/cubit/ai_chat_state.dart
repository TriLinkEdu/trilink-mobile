part of 'ai_chat_cubit.dart';

class AiChatState extends Equatable {
  final List<AiChatMessage> messages;
  final bool isResponding;

  const AiChatState({
    this.messages = const [],
    this.isResponding = false,
  });

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    bool? isResponding,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isResponding: isResponding ?? this.isResponding,
    );
  }

  @override
  List<Object?> get props => [messages, isResponding];
}
