class DashboardStatsModel {
  final int streakDays;
  final int totalXp;
  final int level;
  final String levelTitle;
  final double attendancePercent;

  const DashboardStatsModel({
    required this.streakDays,
    required this.totalXp,
    required this.level,
    required this.levelTitle,
    required this.attendancePercent,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      streakDays: json['streakDays'] as int,
      totalXp: json['totalXp'] as int,
      level: json['level'] as int,
      levelTitle: json['levelTitle'] as String,
      attendancePercent: (json['attendancePercent'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'streakDays': streakDays,
        'totalXp': totalXp,
        'level': level,
        'levelTitle': levelTitle,
        'attendancePercent': attendancePercent,
      };
}

class NextUpItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final String subjectId;
  final String subjectName;
  final DateTime dueAt;
  final int participantCount;

  const NextUpItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.subjectId,
    required this.subjectName,
    required this.dueAt,
    required this.participantCount,
  });

  factory NextUpItemModel.fromJson(Map<String, dynamic> json) {
    return NextUpItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      type: json['type'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      dueAt: DateTime.parse(json['dueAt'] as String),
      participantCount: json['participantCount'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'type': type,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'dueAt': dueAt.toIso8601String(),
        'participantCount': participantCount,
      };
}

class DashboardDataModel {
  final DashboardStatsModel stats;
  final NextUpItemModel? nextUp;
  final List<DashboardAnnouncementSnippet> recentAnnouncements;

  const DashboardDataModel({
    required this.stats,
    this.nextUp,
    required this.recentAnnouncements,
  });

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    return DashboardDataModel(
      stats: DashboardStatsModel.fromJson(json['stats']),
      nextUp: json['nextUp'] != null
          ? NextUpItemModel.fromJson(json['nextUp'])
          : null,
      recentAnnouncements: (json['recentAnnouncements'] as List)
          .map((a) =>
              DashboardAnnouncementSnippet.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'stats': stats.toJson(),
        'nextUp': nextUp?.toJson(),
        'recentAnnouncements':
            recentAnnouncements.map((a) => a.toJson()).toList(),
      };
}

class DashboardAnnouncementSnippet {
  final String id;
  final String title;
  final String authorName;
  final String snippet;
  final DateTime createdAt;

  const DashboardAnnouncementSnippet({
    required this.id,
    required this.title,
    required this.authorName,
    required this.snippet,
    required this.createdAt,
  });

  factory DashboardAnnouncementSnippet.fromJson(Map<String, dynamic> json) {
    return DashboardAnnouncementSnippet(
      id: json['id'] as String,
      title: json['title'] as String,
      authorName: json['authorName'] as String,
      snippet: json['snippet'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'authorName': authorName,
        'snippet': snippet,
        'createdAt': createdAt.toIso8601String(),
      };
}
