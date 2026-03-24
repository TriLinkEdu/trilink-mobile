class LearningPathItemModel {
  final int step;
  final String title;
  final String subject;
  final String duration;
  final double progress;
  final bool isActive;

  const LearningPathItemModel({
    required this.step,
    required this.title,
    required this.subject,
    required this.duration,
    required this.progress,
    required this.isActive,
  });
}

class ResourceRecommendationModel {
  final String id;
  final String title;
  final String type;
  final String estimatedTime;
  final String level;

  const ResourceRecommendationModel({
    required this.id,
    required this.title,
    required this.type,
    required this.estimatedTime,
    required this.level,
  });
}

class EvaluateInsightModel {
  final String title;
  final String summary;
  final String recommendation;

  const EvaluateInsightModel({
    required this.title,
    required this.summary,
    required this.recommendation,
  });
}

class AiAssistantData {
  final List<LearningPathItemModel> learningPath;
  final List<ResourceRecommendationModel> resources;
  final List<EvaluateInsightModel> insights;

  const AiAssistantData({
    required this.learningPath,
    required this.resources,
    required this.insights,
  });
}
