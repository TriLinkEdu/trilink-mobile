import '../models/ai_assistant_models.dart';

abstract class StudentAiAssistantRepository {
  Future<AiAssistantData> fetchAssistantData();

  /// Send a student message and receive a fully-built reply that includes
  /// any source citations returned by the AI engine.
  Future<AiChatMessage> getAiResponse(String message);

  /// Recent conversation history for the current student (most recent last).
  /// Returns an empty list if the backend has none or the call fails.
  Future<List<AiChatMessage>> fetchChatHistory({int limit = 20});
}
