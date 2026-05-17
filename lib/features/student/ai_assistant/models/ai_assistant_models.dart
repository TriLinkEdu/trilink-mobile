class AiChatSource {
  final String title;
  final String? topicId;
  final double? score;

  const AiChatSource({required this.title, this.topicId, this.score});
}

class AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<AiChatSource>? sources;
  final bool isError;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources,
    this.isError = false,
  });

  factory AiChatMessage.fromBackendResponse(Map<String, dynamic> json) {
    return AiChatMessage(
      text: json['answer'] as String,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}

class LearningPathItemModel {
  final String topicId;
  final String topicName;
  final double currentMastery;
  final double targetMastery;
  final int sequenceOrder;
  final bool isCompleted;
  final String? explanation;

  const LearningPathItemModel({
    required this.topicId,
    required this.topicName,
    required this.currentMastery,
    required this.targetMastery,
    required this.sequenceOrder,
    required this.isCompleted,
    this.explanation,
  });

  // Derived helpers used by widgets.
  int get step => sequenceOrder;
  String get title => topicName;
  double get progress =>
      targetMastery > 0 ? (currentMastery / targetMastery).clamp(0, 1) : 0;
  bool get isActive => !isCompleted;
  bool get isBookmarked => false;
  /// Subject is not part of the AI response — fall back to a readable placeholder.
  String get subject => 'Topic';
  /// Duration estimate derived from mastery gap (rough heuristic).
  String get duration {
    final gap = (targetMastery - currentMastery).clamp(0.0, 1.0);
    final minutes = (gap * 60).round();
    if (minutes < 10) return '~10 min';
    return '~$minutes min';
  }

  /// Human-readable mastery summary, e.g. "62% mastery · target 80%".
  String get masterySummary {
    final current = (currentMastery * 100).round();
    final target = (targetMastery * 100).round();
    return '$current% mastery · target $target%';
  }

  LearningPathItemModel copyWith({
    String? topicId,
    String? topicName,
    double? currentMastery,
    double? targetMastery,
    int? sequenceOrder,
    bool? isCompleted,
    String? explanation,
  }) {
    return LearningPathItemModel(
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      currentMastery: currentMastery ?? this.currentMastery,
      targetMastery: targetMastery ?? this.targetMastery,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      isCompleted: isCompleted ?? this.isCompleted,
      explanation: explanation ?? this.explanation,
    );
  }

  factory LearningPathItemModel.fromJson(Map<String, dynamic> json) {
    return LearningPathItemModel(
      topicId: json['topic_id'] as String,
      topicName: json['topic_name'] as String,
      currentMastery: (json['current_mastery'] as num).toDouble(),
      targetMastery: (json['target_mastery'] as num).toDouble(),
      sequenceOrder: json['sequence_order'] as int,
      isCompleted: json['is_completed'] as bool,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'topic_id': topicId,
    'topic_name': topicName,
    'current_mastery': currentMastery,
    'target_mastery': targetMastery,
    'sequence_order': sequenceOrder,
    'is_completed': isCompleted,
    'explanation': explanation,
  };
}

class ResourceRecommendationModel {
  final String type;
  final String title;
  final String url;
  final String difficulty;
  final String? description;

  const ResourceRecommendationModel({
    required this.type,
    required this.title,
    required this.url,
    required this.difficulty,
    this.description,
  });

  // Derived helpers.
  String get id => url;
  String get level => difficulty;
  /// Estimated read/watch time based on resource type.
  String get estimatedTime {
    return switch (type.toLowerCase()) {
      'video' => '~10 min',
      'article' => '~5 min',
      'worksheet' => '~15 min',
      _ => '~10 min',
    };
  }

  factory ResourceRecommendationModel.fromJson(Map<String, dynamic> json) {
    return ResourceRecommendationModel(
      type: json['type'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      difficulty: json['difficulty'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'url': url,
    'difficulty': difficulty,
    'description': description,
  };
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

  factory EvaluateInsightModel.fromJson(Map<String, dynamic> json) {
    return EvaluateInsightModel(
      title: json['title'] as String,
      summary: json['summary'] as String,
      recommendation: json['recommendation'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'summary': summary,
    'recommendation': recommendation,
  };
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

  factory AiAssistantData.fromJson(Map<String, dynamic> json) {
    return AiAssistantData(
      learningPath: (json['learningPath'] as List)
          .map((e) => LearningPathItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      resources: (json['resources'] as List)
          .map(
            (e) =>
                ResourceRecommendationModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      insights: (json['insights'] as List)
          .map((e) => EvaluateInsightModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'learningPath': learningPath.map((e) => e.toJson()).toList(),
    'resources': resources.map((e) => e.toJson()).toList(),
    'insights': insights.map((e) => e.toJson()).toList(),
  };
}
