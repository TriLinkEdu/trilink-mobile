import '../models/ai_assistant_models.dart';

abstract class StudentAiAssistantRepository {
  Future<AiAssistantData> fetchAssistantData();
}
