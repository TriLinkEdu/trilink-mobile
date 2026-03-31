import '../models/gamification_models.dart';
import '../../exams/models/exam_model.dart';
import 'student_gamification_repository.dart';

class MockStudentGamificationRepository
    implements StudentGamificationRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  static final Map<String, List<LeaderboardEntry>> _leaderboards = {
    'weekly': [
      const LeaderboardEntry(studentId: 's1', studentName: 'Sara Ahmed', rank: 1, points: 520),
      const LeaderboardEntry(studentId: 's2', studentName: 'Dawit Bekele', rank: 2, points: 480),
      const LeaderboardEntry(studentId: 's3', studentName: 'Hana Tadesse', rank: 3, points: 455),
      const LeaderboardEntry(studentId: 's4', studentName: 'Yonas Kebede', rank: 4, points: 430),
      const LeaderboardEntry(studentId: 's5', studentName: 'Liya Mengistu', rank: 5, points: 410),
      const LeaderboardEntry(studentId: 's6', studentName: 'Abel Gebre', rank: 6, points: 385),
      const LeaderboardEntry(studentId: 's7', studentName: 'Meron Hailu', rank: 7, points: 360),
      const LeaderboardEntry(studentId: 's8', studentName: 'Kaleb Alemu', rank: 8, points: 340),
      const LeaderboardEntry(studentId: 's9', studentName: 'Selam Worku', rank: 9, points: 310),
      const LeaderboardEntry(studentId: 's10', studentName: 'Naod Tesfaye', rank: 10, points: 290),
    ],
    'monthly': [
      const LeaderboardEntry(studentId: 's2', studentName: 'Dawit Bekele', rank: 1, points: 2150),
      const LeaderboardEntry(studentId: 's1', studentName: 'Sara Ahmed', rank: 2, points: 2080),
      const LeaderboardEntry(studentId: 's5', studentName: 'Liya Mengistu', rank: 3, points: 1920),
      const LeaderboardEntry(studentId: 's3', studentName: 'Hana Tadesse', rank: 4, points: 1870),
      const LeaderboardEntry(studentId: 's7', studentName: 'Meron Hailu', rank: 5, points: 1750),
      const LeaderboardEntry(studentId: 's4', studentName: 'Yonas Kebede', rank: 6, points: 1680),
      const LeaderboardEntry(studentId: 's9', studentName: 'Selam Worku', rank: 7, points: 1590),
      const LeaderboardEntry(studentId: 's6', studentName: 'Abel Gebre', rank: 8, points: 1520),
      const LeaderboardEntry(studentId: 's10', studentName: 'Naod Tesfaye', rank: 9, points: 1430),
      const LeaderboardEntry(studentId: 's8', studentName: 'Kaleb Alemu', rank: 10, points: 1380),
    ],
  };

  static final List<AchievementModel> _achievements = [
    AchievementModel(
      id: 'ach-1',
      title: 'First Steps',
      description: 'Complete your first quiz.',
      iconUrl: 'assets/achievements/first_steps.png',
      isUnlocked: true,
      unlockedAt: DateTime(2024, 1, 15),
    ),
    AchievementModel(
      id: 'ach-2',
      title: 'Perfect Score',
      description: 'Score 100% on any quiz.',
      iconUrl: 'assets/achievements/perfect_score.png',
      isUnlocked: true,
      unlockedAt: DateTime(2024, 2, 3),
    ),
    AchievementModel(
      id: 'ach-3',
      title: 'Week Warrior',
      description: 'Maintain a 7-day streak.',
      iconUrl: 'assets/achievements/week_warrior.png',
      isUnlocked: true,
      unlockedAt: DateTime(2024, 2, 20),
    ),
    AchievementModel(
      id: 'ach-4',
      title: 'Quiz Master',
      description: 'Complete 25 quizzes.',
      iconUrl: 'assets/achievements/quiz_master.png',
      isUnlocked: true,
      unlockedAt: DateTime(2024, 3, 5),
    ),
    AchievementModel(
      id: 'ach-5',
      title: 'Top of the Class',
      description: 'Reach rank 1 on the weekly leaderboard.',
      iconUrl: 'assets/achievements/top_class.png',
      isUnlocked: true,
      unlockedAt: DateTime(2024, 3, 12),
    ),
    const AchievementModel(
      id: 'ach-6',
      title: 'Month Marathon',
      description: 'Maintain a 30-day streak.',
      iconUrl: 'assets/achievements/month_marathon.png',
      isUnlocked: false,
    ),
    const AchievementModel(
      id: 'ach-7',
      title: 'Subject Specialist',
      description: 'Score above 90% in 10 quizzes of the same subject.',
      iconUrl: 'assets/achievements/specialist.png',
      isUnlocked: false,
    ),
    const AchievementModel(
      id: 'ach-8',
      title: 'Social Learner',
      description: 'Help 5 classmates through the chat feature.',
      iconUrl: 'assets/achievements/social_learner.png',
      isUnlocked: false,
    ),
    const AchievementModel(
      id: 'ach-9',
      title: 'Knowledge Explorer',
      description: 'Complete quizzes in all available subjects.',
      iconUrl: 'assets/achievements/explorer.png',
      isUnlocked: false,
    ),
    const AchievementModel(
      id: 'ach-10',
      title: 'Legend',
      description: 'Earn 5000 total XP.',
      iconUrl: 'assets/achievements/legend.png',
      isUnlocked: false,
    ),
  ];

  static final Map<String, ExamModel> _quizzes = {
    'mathematics': const ExamModel(
      id: 'quiz-math-1',
      title: 'Mathematics Quick Quiz',
      subjectId: 'mathematics',
      subjectName: 'Mathematics',
      durationMinutes: 10,
      questions: [
        QuestionModel(
          id: 'qm1',
          text: 'What is the derivative of x²?',
          options: ['x', '2x', '2', 'x²'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'qm2',
          text: 'What is the value of √144?',
          options: ['10', '11', '12', '14'],
          correctIndex: 2,
        ),
        QuestionModel(
          id: 'qm3',
          text: 'Solve: 3x + 7 = 22. What is x?',
          options: ['3', '5', '7', '15'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'qm4',
          text: 'What is the area of a circle with radius 5?',
          options: ['25π', '10π', '5π', '50π'],
          correctIndex: 0,
        ),
        QuestionModel(
          id: 'qm5',
          text: 'What is log₁₀(1000)?',
          options: ['2', '3', '4', '10'],
          correctIndex: 1,
        ),
      ],
    ),
    'physics': const ExamModel(
      id: 'quiz-phys-1',
      title: 'Physics Quick Quiz',
      subjectId: 'physics',
      subjectName: 'Physics',
      durationMinutes: 10,
      questions: [
        QuestionModel(
          id: 'qp1',
          text: 'What is the SI unit of force?',
          options: ['Watt', 'Joule', 'Newton', 'Pascal'],
          correctIndex: 2,
        ),
        QuestionModel(
          id: 'qp2',
          text: 'What is the acceleration due to gravity on Earth?',
          options: ['8.9 m/s²', '9.8 m/s²', '10.8 m/s²', '11.2 m/s²'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'qp3',
          text: 'Which law states F = ma?',
          options: [
            "Newton's First Law",
            "Newton's Second Law",
            "Newton's Third Law",
            "Law of Gravitation",
          ],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'qp4',
          text: 'What is the speed of light in vacuum?',
          options: [
            '3 × 10⁶ m/s',
            '3 × 10⁸ m/s',
            '3 × 10¹⁰ m/s',
            '3 × 10⁴ m/s',
          ],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'qp5',
          text: 'What type of energy does a moving car have?',
          options: [
            'Potential energy',
            'Kinetic energy',
            'Thermal energy',
            'Chemical energy',
          ],
          correctIndex: 1,
        ),
      ],
    ),
    'literature': const ExamModel(
      id: 'quiz-lit-1',
      title: 'Literature Quick Quiz',
      subjectId: 'literature',
      subjectName: 'Literature',
      durationMinutes: 10,
      questions: [
        QuestionModel(
          id: 'ql1',
          text: 'Who wrote "Romeo and Juliet"?',
          options: [
            'Charles Dickens',
            'William Shakespeare',
            'Jane Austen',
            'Mark Twain',
          ],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'ql2',
          text: 'What is a sonnet?',
          options: [
            'A 10-line poem',
            'A 14-line poem',
            'A 20-line poem',
            'A type of novel',
          ],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'ql3',
          text: 'What literary device compares two things using "like" or "as"?',
          options: ['Metaphor', 'Simile', 'Hyperbole', 'Alliteration'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'ql4',
          text: 'Who is the author of "1984"?',
          options: [
            'Aldous Huxley',
            'George Orwell',
            'Ray Bradbury',
            'H.G. Wells',
          ],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'ql5',
          text: 'What is the main conflict type in "man vs. nature" stories?',
          options: [
            'Internal conflict',
            'External conflict',
            'Moral conflict',
            'Social conflict',
          ],
          correctIndex: 1,
        ),
      ],
    ),
  };

  static final List<QuizModel> _availableQuizzes = const [
    QuizModel(
      id: 'quiz-math-1',
      title: 'Calculus Fundamentals',
      subjectId: 'mathematics',
      subjectName: 'Mathematics',
      questionCount: 5,
      xpReward: 50,
      difficulty: 'medium',
    ),
    QuizModel(
      id: 'quiz-phys-1',
      title: 'Mechanics Basics',
      subjectId: 'physics',
      subjectName: 'Physics',
      questionCount: 5,
      xpReward: 50,
      difficulty: 'medium',
    ),
    QuizModel(
      id: 'quiz-lit-1',
      title: 'Classical Literature',
      subjectId: 'literature',
      subjectName: 'Literature',
      questionCount: 5,
      xpReward: 40,
      difficulty: 'easy',
    ),
    QuizModel(
      id: 'quiz-hist-1',
      title: 'World History Overview',
      subjectId: 'history',
      subjectName: 'History',
      questionCount: 5,
      xpReward: 45,
      difficulty: 'medium',
    ),
    QuizModel(
      id: 'quiz-cs-1',
      title: 'Intro to Algorithms',
      subjectId: 'computer-science',
      subjectName: 'Computer Science',
      questionCount: 5,
      xpReward: 60,
      difficulty: 'hard',
    ),
  ];

  static final List<BadgeModel> _badges = [
    const BadgeModel(
      id: 'badge-addis-attendance',
      name: 'Addis Perfect Week',
      description:
          'No absences for a full school week at your Addis Ababa secondary school.',
      iconUrl: 'assets/badges/addis_perfect_week.png',
      xpValue: 75,
    ),
    const BadgeModel(
      id: 'badge-ethiopian-studies',
      name: 'Civics & Ethiopian History Star',
      description:
          'Earned top marks on the Ethiopian civics and history checkpoint quiz.',
      iconUrl: 'assets/badges/ethiopian_studies.png',
      xpValue: 120,
    ),
    const BadgeModel(
      id: 'badge-amharic-english',
      name: 'Bilingual Learner',
      description:
          'Completed Amharic and English language activities in the same term.',
      iconUrl: 'assets/badges/bilingual_learner.png',
      xpValue: 90,
    ),
    const BadgeModel(
      id: 'badge-national-exam-prep',
      name: 'Grade 12 Prep Streak',
      description:
          'Studied on TriLink for 14 consecutive days during national exam preparation.',
      iconUrl: 'assets/badges/grade12_prep.png',
      xpValue: 150,
    ),
    const BadgeModel(
      id: 'badge-science-fair',
      name: 'Regional Science Fair Participant',
      description:
          'Submitted a project for your school science fair and shared it with classmates.',
      iconUrl: 'assets/badges/science_fair.png',
      xpValue: 200,
    ),
  ];

  static final Map<String, List<StudentBadgeModel>> _studentBadgesById = {
    'student1': [
      StudentBadgeModel(
        studentId: 'student1',
        badge: _badges[0],
        awardedAt: DateTime(2025, 10, 6),
      ),
      StudentBadgeModel(
        studentId: 'student1',
        badge: _badges[1],
        awardedAt: DateTime(2025, 11, 3),
      ),
      StudentBadgeModel(
        studentId: 'student1',
        badge: _badges[3],
        awardedAt: DateTime(2026, 1, 20),
      ),
    ],
  };

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard(String period) async {
    await Future<void>.delayed(_latency);
    return List<LeaderboardEntry>.from(
      _leaderboards[period] ?? _leaderboards['weekly']!,
    );
  }

  @override
  Future<List<AchievementModel>> fetchAchievements() async {
    await Future<void>.delayed(_latency);
    return List<AchievementModel>.from(_achievements);
  }

  @override
  Future<ExamModel> fetchQuiz(String subjectId) async {
    await Future<void>.delayed(_latency);
    final quiz = _quizzes[subjectId];
    if (quiz == null) {
      throw Exception('No quiz found for subject: $subjectId');
    }
    return quiz;
  }

  @override
  Future<ExamResultModel> submitQuizAnswers(
    String quizId,
    Map<String, int> answers,
  ) async {
    await Future<void>.delayed(_latency);

    final quiz = _quizzes.values.firstWhere(
      (q) => q.id == quizId,
      orElse: () => throw Exception('Quiz not found: $quizId'),
    );

    int correct = 0;
    for (final question in quiz.questions) {
      final selected = answers[question.id];
      if (selected != null && selected == question.correctIndex) {
        correct++;
      }
    }

    final total = quiz.questions.length;
    final score = total > 0 ? (correct / total) * 100 : 0.0;
    final xpEarned = (correct * 10) + (score == 100 ? 20 : 0);

    return ExamResultModel(
      examId: quizId,
      examTitle: quiz.title,
      totalQuestions: total,
      correctAnswers: correct,
      score: score,
      xpEarned: xpEarned.toInt(),
      answerMap: answers,
    );
  }

  @override
  Future<StreakModel> fetchStreak() async {
    await Future<void>.delayed(_latency);
    final now = DateTime.now();
    return StreakModel(
      currentStreak: 12,
      longestStreak: 25,
      recentDays: List.generate(
        7,
        (i) => DateTime(now.year, now.month, now.day - (6 - i)),
      ),
    );
  }

  @override
  Future<List<QuizModel>> fetchAvailableQuizzes() async {
    await Future<void>.delayed(_latency);
    return List<QuizModel>.from(_availableQuizzes);
  }

  @override
  Future<List<BadgeModel>> fetchBadges() async {
    await Future<void>.delayed(_latency);
    return List<BadgeModel>.from(_badges);
  }

  @override
  Future<List<StudentBadgeModel>> fetchStudentBadges(String studentId) async {
    await Future<void>.delayed(_latency);
    return List<StudentBadgeModel>.from(
      _studentBadgesById[studentId] ?? const <StudentBadgeModel>[],
    );
  }
}
