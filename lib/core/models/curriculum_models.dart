enum DifficultyTier { easy, medium, hard }

class SubjectModel {
  final String id;
  final String name;
  final String code;
  final String curriculumVersion;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.code,
    this.curriculumVersion = '2013EC',
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      curriculumVersion: json['curriculumVersion'] as String? ?? '2013EC',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'curriculumVersion': curriculumVersion,
      };
}

class TopicModel {
  final String id;
  final String subjectId;
  final String? parentTopicId;
  final String name;
  final DifficultyTier difficulty;
  final List<TopicModel> subtopics;

  const TopicModel({
    required this.id,
    required this.subjectId,
    this.parentTopicId,
    required this.name,
    this.difficulty = DifficultyTier.medium,
    this.subtopics = const [],
  });

  bool get isSubtopic => parentTopicId != null;

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      parentTopicId: json['parentTopicId'] as String?,
      name: json['name'] as String,
      difficulty: DifficultyTier.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => DifficultyTier.medium,
      ),
      subtopics: (json['subtopics'] as List?)
              ?.map((t) => TopicModel.fromJson(t as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'parentTopicId': parentTopicId,
        'name': name,
        'difficulty': difficulty.name,
        'subtopics': subtopics.map((t) => t.toJson()).toList(),
      };
}
