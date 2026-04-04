import 'package:equatable/equatable.dart';

import '../models/ai_assistant_models.dart';

enum AiAssistantStatus { initial, loading, loaded, error }

class AiAssistantState extends Equatable {
  final AiAssistantStatus status;
  final AiAssistantData? data;
  final String? errorMessage;

  const AiAssistantState({
    this.status = AiAssistantStatus.initial,
    this.data,
    this.errorMessage,
  });

  AiAssistantState copyWith({
    AiAssistantStatus? status,
    AiAssistantData? data,
    String? errorMessage,
  }) {
    return AiAssistantState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
