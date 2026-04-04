enum AssignmentStatus { pending, submitted, graded, overdue }

class AssignmentModel {
  final String id;
  final String title;
  final String subject;
  final String description;
  final DateTime dueDate;
  final AssignmentStatus status;
  final double? score;
  final double? maxScore;
  final String? feedback;
  final DateTime? submittedAt;
  final String? submittedContent;

  const AssignmentModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.dueDate,
    required this.status,
    this.score,
    this.maxScore,
    this.feedback,
    this.submittedAt,
    this.submittedContent,
  });

  String get statusLabel {
    switch (status) {
      case AssignmentStatus.pending:
        return 'Pending';
      case AssignmentStatus.submitted:
        return 'Submitted';
      case AssignmentStatus.graded:
        return 'Graded';
      case AssignmentStatus.overdue:
        return 'Overdue';
    }
  }

  String get dueDateLabel {
    final now = DateTime.now();
    final diff = dueDate.difference(now).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days';
  }

  AssignmentModel copyWith({
    String? id,
    String? title,
    String? subject,
    String? description,
    DateTime? dueDate,
    AssignmentStatus? status,
    double? score,
    double? maxScore,
    String? feedback,
    DateTime? submittedAt,
    String? submittedContent,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      feedback: feedback ?? this.feedback,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedContent: submittedContent ?? this.submittedContent,
    );
  }

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: AssignmentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => AssignmentStatus.pending,
      ),
      score: (json['score'] as num?)?.toDouble(),
      maxScore: (json['maxScore'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      submittedContent: json['submittedContent'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'status': status.name,
        'score': score,
        'maxScore': maxScore,
        'feedback': feedback,
        'submittedAt': submittedAt?.toIso8601String(),
        'submittedContent': submittedContent,
      };
}
