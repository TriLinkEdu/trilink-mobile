import 'package:flutter/material.dart';

/// Reading progress and state for a textbook
class TextbookReadingState {
  final String textbookId;
  final int currentPage;
  final int totalPages;
  final double scrollPosition;
  final double zoomLevel;
  final DateTime lastReadAt;
  final Duration totalReadingTime;
  final Set<int> bookmarkedPages;
  final List<TextHighlight> highlights;
  final List<TextAnnotation> annotations;
  final bool nightMode;
  final double brightness;
  final double fontSize;

  const TextbookReadingState({
    required this.textbookId,
    this.currentPage = 1,
    this.totalPages = 0,
    this.scrollPosition = 0.0,
    this.zoomLevel = 1.0,
    required this.lastReadAt,
    this.totalReadingTime = Duration.zero,
    this.bookmarkedPages = const {},
    this.highlights = const [],
    this.annotations = const [],
    this.nightMode = false,
    this.brightness = 1.0,
    this.fontSize = 1.0,
  });

  double get progressPercent => totalPages > 0 ? currentPage / totalPages : 0.0;

  TextbookReadingState copyWith({
    int? currentPage,
    int? totalPages,
    double? scrollPosition,
    double? zoomLevel,
    DateTime? lastReadAt,
    Duration? totalReadingTime,
    Set<int>? bookmarkedPages,
    List<TextHighlight>? highlights,
    List<TextAnnotation>? annotations,
    bool? nightMode,
    double? brightness,
    double? fontSize,
  }) {
    return TextbookReadingState(
      textbookId: textbookId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      totalReadingTime: totalReadingTime ?? this.totalReadingTime,
      bookmarkedPages: bookmarkedPages ?? this.bookmarkedPages,
      highlights: highlights ?? this.highlights,
      annotations: annotations ?? this.annotations,
      nightMode: nightMode ?? this.nightMode,
      brightness: brightness ?? this.brightness,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  Map<String, dynamic> toJson() => {
    'textbookId': textbookId,
    'currentPage': currentPage,
    'totalPages': totalPages,
    'scrollPosition': scrollPosition,
    'zoomLevel': zoomLevel,
    'lastReadAt': lastReadAt.toIso8601String(),
    'totalReadingTime': totalReadingTime.inSeconds,
    'bookmarkedPages': bookmarkedPages.toList(),
    'highlights': highlights.map((h) => h.toJson()).toList(),
    'annotations': annotations.map((a) => a.toJson()).toList(),
    'nightMode': nightMode,
    'brightness': brightness,
    'fontSize': fontSize,
  };

  factory TextbookReadingState.fromJson(Map<String, dynamic> json) {
    return TextbookReadingState(
      textbookId: json['textbookId'] as String,
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 0,
      scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0.0,
      zoomLevel: (json['zoomLevel'] as num?)?.toDouble() ?? 1.0,
      lastReadAt: DateTime.parse(json['lastReadAt'] as String),
      totalReadingTime: Duration(seconds: json['totalReadingTime'] as int? ?? 0),
      bookmarkedPages: Set<int>.from(json['bookmarkedPages'] as List? ?? []),
      highlights: (json['highlights'] as List?)
          ?.map((h) => TextHighlight.fromJson(h as Map<String, dynamic>))
          .toList() ?? [],
      annotations: (json['annotations'] as List?)
          ?.map((a) => TextAnnotation.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
      nightMode: json['nightMode'] as bool? ?? false,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 1.0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Text highlight in a textbook
class TextHighlight {
  final String id;
  final int pageNumber;
  final Rect bounds;
  final String text;
  final Color color;
  final DateTime createdAt;

  const TextHighlight({
    required this.id,
    required this.pageNumber,
    required this.bounds,
    required this.text,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageNumber': pageNumber,
    'bounds': {
      'left': bounds.left,
      'top': bounds.top,
      'right': bounds.right,
      'bottom': bounds.bottom,
    },
    'text': text,
    'color': color.value,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TextHighlight.fromJson(Map<String, dynamic> json) {
    final boundsJson = json['bounds'] as Map<String, dynamic>;
    return TextHighlight(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      bounds: Rect.fromLTRB(
        (boundsJson['left'] as num).toDouble(),
        (boundsJson['top'] as num).toDouble(),
        (boundsJson['right'] as num).toDouble(),
        (boundsJson['bottom'] as num).toDouble(),
      ),
      text: json['text'] as String,
      color: Color(json['color'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Text annotation/note in a textbook
class TextAnnotation {
  final String id;
  final int pageNumber;
  final Offset position;
  final String note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TextAnnotation({
    required this.id,
    required this.pageNumber,
    required this.position,
    required this.note,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageNumber': pageNumber,
    'position': {'x': position.dx, 'y': position.dy},
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory TextAnnotation.fromJson(Map<String, dynamic> json) {
    final posJson = json['position'] as Map<String, dynamic>;
    return TextAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      position: Offset(
        (posJson['x'] as num).toDouble(),
        (posJson['y'] as num).toDouble(),
      ),
      note: json['note'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }
}

/// Search result in textbook
class TextbookSearchResult {
  final int pageNumber;
  final String snippet;
  final List<TextMatch> matches;

  const TextbookSearchResult({
    required this.pageNumber,
    required this.snippet,
    required this.matches,
  });
}

/// Individual text match within a search result
class TextMatch {
  final int startIndex;
  final int endIndex;
  final String matchedText;

  const TextMatch({
    required this.startIndex,
    required this.endIndex,
    required this.matchedText,
  });
}

/// Table of contents entry
class TocEntry {
  final String title;
  final int pageNumber;
  final int level;
  final List<TocEntry> children;

  const TocEntry({
    required this.title,
    required this.pageNumber,
    required this.level,
    this.children = const [],
  });
}