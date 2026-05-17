import '../../../../core/models/curriculum_models.dart';
import 'student_curriculum_repository.dart';

class MockStudentCurriculumRepository implements StudentCurriculumRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  static final List<SubjectModel> _subjects = [
    const SubjectModel(
      id: 'mathematics',
      name: 'Mathematics',
      code: 'MATH-301',
    ),
    const SubjectModel(
      id: 'physics',
      name: 'Physics',
      code: 'PHY-201',
    ),
    const SubjectModel(
      id: 'literature',
      name: 'Literature',
      code: 'LIT-101',
    ),
    const SubjectModel(
      id: 'history',
      name: 'History',
      code: 'HIST-202',
    ),
    const SubjectModel(
      id: 'computer_science',
      name: 'Computer Science',
      code: 'CS-401',
    ),
  ];

  static final Map<String, List<TopicModel>> _topicsBySubject = {
    'mathematics': [
      TopicModel(
        id: 'math-algebra',
        subjectId: 'mathematics',
        name: 'Algebra',
        difficulty: DifficultyTier.easy,
        subtopics: [
          TopicModel(
            id: 'math-algebra-linear',
            subjectId: 'mathematics',
            parentTopicId: 'math-algebra',
            name: 'Linear Equations',
            difficulty: DifficultyTier.easy,
          ),
          TopicModel(
            id: 'math-algebra-quadratic',
            subjectId: 'mathematics',
            parentTopicId: 'math-algebra',
            name: 'Quadratic Equations',
            difficulty: DifficultyTier.medium,
          ),
        ],
      ),
      TopicModel(
        id: 'math-calculus',
        subjectId: 'mathematics',
        name: 'Calculus',
        difficulty: DifficultyTier.hard,
        subtopics: [
          TopicModel(
            id: 'math-calculus-limits',
            subjectId: 'mathematics',
            parentTopicId: 'math-calculus',
            name: 'Limits',
            difficulty: DifficultyTier.medium,
          ),
          TopicModel(
            id: 'math-calculus-derivatives',
            subjectId: 'mathematics',
            parentTopicId: 'math-calculus',
            name: 'Derivatives',
            difficulty: DifficultyTier.hard,
          ),
        ],
      ),
      TopicModel(
        id: 'math-geometry',
        subjectId: 'mathematics',
        name: 'Geometry',
        difficulty: DifficultyTier.medium,
        subtopics: [
          TopicModel(
            id: 'math-geometry-triangles',
            subjectId: 'mathematics',
            parentTopicId: 'math-geometry',
            name: 'Triangles',
            difficulty: DifficultyTier.easy,
          ),
        ],
      ),
      TopicModel(
        id: 'math-statistics',
        subjectId: 'mathematics',
        name: 'Statistics',
        difficulty: DifficultyTier.medium,
        subtopics: const [],
      ),
    ],
    'physics': [
      TopicModel(
        id: 'phy-mechanics',
        subjectId: 'physics',
        name: 'Mechanics',
        difficulty: DifficultyTier.medium,
        subtopics: [
          TopicModel(
            id: 'phy-mechanics-kinematics',
            subjectId: 'physics',
            parentTopicId: 'phy-mechanics',
            name: 'Kinematics',
            difficulty: DifficultyTier.easy,
          ),
          TopicModel(
            id: 'phy-mechanics-dynamics',
            subjectId: 'physics',
            parentTopicId: 'phy-mechanics',
            name: 'Dynamics',
            difficulty: DifficultyTier.hard,
          ),
        ],
      ),
      TopicModel(
        id: 'phy-thermo',
        subjectId: 'physics',
        name: 'Thermodynamics',
        difficulty: DifficultyTier.hard,
        subtopics: [
          TopicModel(
            id: 'phy-thermo-laws',
            subjectId: 'physics',
            parentTopicId: 'phy-thermo',
            name: 'Laws of Thermodynamics',
            difficulty: DifficultyTier.medium,
          ),
        ],
      ),
      TopicModel(
        id: 'phy-waves',
        subjectId: 'physics',
        name: 'Waves and Optics',
        difficulty: DifficultyTier.medium,
        subtopics: const [],
      ),
    ],
    'literature': [
      TopicModel(
        id: 'lit-poetry',
        subjectId: 'literature',
        name: 'Poetry',
        difficulty: DifficultyTier.medium,
        subtopics: [
          TopicModel(
            id: 'lit-poetry-metaphor',
            subjectId: 'literature',
            parentTopicId: 'lit-poetry',
            name: 'Metaphor and Imagery',
            difficulty: DifficultyTier.easy,
          ),
        ],
      ),
      TopicModel(
        id: 'lit-novel',
        subjectId: 'literature',
        name: 'The Novel',
        difficulty: DifficultyTier.medium,
        subtopics: [
          TopicModel(
            id: 'lit-novel-structure',
            subjectId: 'literature',
            parentTopicId: 'lit-novel',
            name: 'Narrative Structure',
            difficulty: DifficultyTier.medium,
          ),
          TopicModel(
            id: 'lit-novel-character',
            subjectId: 'literature',
            parentTopicId: 'lit-novel',
            name: 'Character Analysis',
            difficulty: DifficultyTier.hard,
          ),
        ],
      ),
      TopicModel(
        id: 'lit-drama',
        subjectId: 'literature',
        name: 'Drama',
        difficulty: DifficultyTier.easy,
        subtopics: const [],
      ),
    ],
    'history': [
      TopicModel(
        id: 'hist-ancient',
        subjectId: 'history',
        name: 'Ancient Civilizations',
        difficulty: DifficultyTier.medium,
        subtopics: [
          TopicModel(
            id: 'hist-ancient-egypt',
            subjectId: 'history',
            parentTopicId: 'hist-ancient',
            name: 'Egypt',
            difficulty: DifficultyTier.easy,
          ),
        ],
      ),
      TopicModel(
        id: 'hist-modern',
        subjectId: 'history',
        name: 'Modern World History',
        difficulty: DifficultyTier.hard,
        subtopics: [
          TopicModel(
            id: 'hist-modern-ww',
            subjectId: 'history',
            parentTopicId: 'hist-modern',
            name: 'World Wars',
            difficulty: DifficultyTier.hard,
          ),
        ],
      ),
      TopicModel(
        id: 'hist-local',
        subjectId: 'history',
        name: 'Regional History',
        difficulty: DifficultyTier.medium,
        subtopics: const [],
      ),
      TopicModel(
        id: 'hist-research',
        subjectId: 'history',
        name: 'Historical Methods',
        difficulty: DifficultyTier.medium,
        subtopics: const [],
      ),
    ],
    'computer_science': [
      TopicModel(
        id: 'cs-programming',
        subjectId: 'computer_science',
        name: 'Programming Fundamentals',
        difficulty: DifficultyTier.easy,
        subtopics: [
          TopicModel(
            id: 'cs-programming-control',
            subjectId: 'computer_science',
            parentTopicId: 'cs-programming',
            name: 'Control Flow',
            difficulty: DifficultyTier.easy,
          ),
          TopicModel(
            id: 'cs-programming-functions',
            subjectId: 'computer_science',
            parentTopicId: 'cs-programming',
            name: 'Functions',
            difficulty: DifficultyTier.medium,
          ),
        ],
      ),
      TopicModel(
        id: 'cs-ds',
        subjectId: 'computer_science',
        name: 'Data Structures',
        difficulty: DifficultyTier.hard,
        subtopics: [
          TopicModel(
            id: 'cs-ds-trees',
            subjectId: 'computer_science',
            parentTopicId: 'cs-ds',
            name: 'Trees and Graphs',
            difficulty: DifficultyTier.hard,
          ),
        ],
      ),
      TopicModel(
        id: 'cs-algo',
        subjectId: 'computer_science',
        name: 'Algorithms',
        difficulty: DifficultyTier.hard,
        subtopics: [
          TopicModel(
            id: 'cs-algo-sorting',
            subjectId: 'computer_science',
            parentTopicId: 'cs-algo',
            name: 'Sorting',
            difficulty: DifficultyTier.medium,
          ),
          TopicModel(
            id: 'cs-algo-complexity',
            subjectId: 'computer_science',
            parentTopicId: 'cs-algo',
            name: 'Complexity Analysis',
            difficulty: DifficultyTier.hard,
          ),
        ],
      ),
    ],
  };

  @override
  Future<List<SubjectModel>> fetchSubjects() async {
    await Future<void>.delayed(_latency);
    return List<SubjectModel>.from(_subjects);
  }

  @override
  Future<List<TopicModel>> fetchTopics(String subjectId) async {
    await Future<void>.delayed(_latency);
    final topics = _topicsBySubject[subjectId] ?? const <TopicModel>[];
    return List<TopicModel>.from(topics);
  }

  @override
  List<SubjectModel>? getCached() => null;

  @override
  void clearCache() {}
}
