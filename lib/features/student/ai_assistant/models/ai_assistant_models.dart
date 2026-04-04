class AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class LearningPathItemModel {
  final int step;
  final String title;
  final String subject;
  final String duration;
  final double progress;
  final bool isActive;
  final bool isBookmarked;

  const LearningPathItemModel({
    required this.step,
    required this.title,
    required this.subject,
    required this.duration,
    required this.progress,
    required this.isActive,
    this.isBookmarked = false,
  });

  LearningPathItemModel copyWith({
    int? step,
    String? title,
    String? subject,
    String? duration,
    double? progress,
    bool? isActive,
    bool? isBookmarked,
  }) {
    return LearningPathItemModel(
      step: step ?? this.step,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      duration: duration ?? this.duration,
      progress: progress ?? this.progress,
      isActive: isActive ?? this.isActive,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  factory LearningPathItemModel.fromJson(Map<String, dynamic> json) {
    return LearningPathItemModel(
      step: json['step'] as int,
      title: json['title'] as String,
      subject: json['subject'] as String,
      duration: json['duration'] as String,
      progress: (json['progress'] as num).toDouble(),
      isActive: json['isActive'] as bool,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'step': step,
    'title': title,
    'subject': subject,
    'duration': duration,
    'progress': progress,
    'isActive': isActive,
    'isBookmarked': isBookmarked,
  };
}

class ResourceRecommendationModel {
  final String id;
  final String title;
  final String type;
  final String estimatedTime;
  final String level;
  final String? url;

  const ResourceRecommendationModel({
    required this.id,
    required this.title,
    required this.type,
    required this.estimatedTime,
    required this.level,
    this.url,
  });

  factory ResourceRecommendationModel.fromJson(Map<String, dynamic> json) {
    return ResourceRecommendationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      estimatedTime: json['estimatedTime'] as String,
      level: json['level'] as String,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'estimatedTime': estimatedTime,
    'level': level,
    'url': url,
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
