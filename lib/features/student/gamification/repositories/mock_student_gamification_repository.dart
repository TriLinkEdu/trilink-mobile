import '../models/gamification_models.dart';
import '../../exams/models/exam_model.dart';
import '../../shared/models/student_progress_model.dart';
import '../../shared/repositories/student_progress_repository.dart';
import 'student_gamification_repository.dart';

class MockStudentGamificationRepository
    implements StudentGamificationRepository {
  static const Duration _latency = Duration(milliseconds: 350);
  final StudentProgressRepository _progressRepository;

  MockStudentGamificationRepository(this._progressRepository);

  static final Map<String, List<LeaderboardEntry>> _leaderboards = {
    'weekly': [
      const LeaderboardEntry(
        studentId: 's1',
        studentName: 'Sara Ahmed',
        rank: 1,
        points: 520,
      ),
      const LeaderboardEntry(
        studentId: 's2',
        studentName: 'Dawit Bekele',
        rank: 2,
        points: 480,
      ),
      const LeaderboardEntry(
        studentId: 's3',
        studentName: 'Hana Tadesse',
        rank: 3,
        points: 455,
      ),
      const LeaderboardEntry(
        studentId: 's4',
        studentName: 'Yonas Kebede',
        rank: 4,
        points: 430,
      ),
      const LeaderboardEntry(
        studentId: 's5',
        studentName: 'Liya Mengistu',
        rank: 5,
        points: 410,
      ),
      const LeaderboardEntry(
        studentId: 's6',
        studentName: 'Abel Gebre',
        rank: 6,
        points: 385,
      ),
      const LeaderboardEntry(
        studentId: 's7',
        studentName: 'Meron Hailu',
        rank: 7,
        points: 360,
      ),
      const LeaderboardEntry(
        studentId: 's8',
        studentName: 'Kaleb Alemu',
        rank: 8,
        points: 340,
      ),
      const LeaderboardEntry(
        studentId: 's9',
        studentName: 'Selam Worku',
        rank: 9,
        points: 310,
      ),
      const LeaderboardEntry(
        studentId: 's10',
        studentName: 'Naod Tesfaye',
        rank: 10,
        points: 290,
      ),
    ],
    'monthly': [
      const LeaderboardEntry(
        studentId: 's2',
        studentName: 'Dawit Bekele',
        rank: 1,
        points: 2150,
      ),
      const LeaderboardEntry(
        studentId: 's1',
        studentName: 'Sara Ahmed',
        rank: 2,
        points: 2080,
      ),
      const LeaderboardEntry(
        studentId: 's5',
        studentName: 'Liya Mengistu',
        rank: 3,
        points: 1920,
      ),
      const LeaderboardEntry(
        studentId: 's3',
        studentName: 'Hana Tadesse',
        rank: 4,
        points: 1870,
      ),
      const LeaderboardEntry(
        studentId: 's7',
        studentName: 'Meron Hailu',
        rank: 5,
        points: 1750,
      ),
      const LeaderboardEntry(
        studentId: 's4',
        studentName: 'Yonas Kebede',
        rank: 6,
        points: 1680,
      ),
      const LeaderboardEntry(
        studentId: 's9',
        studentName: 'Selam Worku',
        rank: 7,
        points: 1590,
      ),
      const LeaderboardEntry(
        studentId: 's6',
        studentName: 'Abel Gebre',
        rank: 8,
        points: 1520,
      ),
      const LeaderboardEntry(
        studentId: 's10',
        studentName: 'Naod Tesfaye',
        rank: 9,
        points: 1430,
      ),
      const LeaderboardEntry(
        studentId: 's8',
        studentName: 'Kaleb Alemu',
        rank: 10,
        points: 1380,
      ),
    ],
  };

  static final List<AchievementModel> _achievements = [
    AchievementModel(
      id: 'ach-1',
      title: 'First Steps',
      description: 'Complete your first quiz.',
      iconUrl: 'assets/achievements/first_steps.png',
      category: AchievementCategory.milestone,
      progressCurrent: 1,
      progressTarget: 1,
      isUnlocked: true,
      unlockedAt: DateTime(2024, 1, 15),
    ),
    AchievementModel(
      id: 'ach-2',
      title: 'Perfect Score',
      description: 'Score 100% on any quiz.',
      iconUrl: 'assets/achievements/perfect_score.png',
      category: AchievementCategory.mastery,
      progressCurrent: 1,
      progressTarget: 1,
      isUnlocked: true,
      unlockedAt: DateTime(2024, 2, 3),
    ),
    AchievementModel(
      id: 'ach-3',
      title: 'Week Warrior',
      description: 'Maintain a 7-day streak.',
      iconUrl: 'assets/achievements/week_warrior.png',
      category: AchievementCategory.consistency,
      progressCurrent: 7,
      progressTarget: 7,
      isUnlocked: true,
      unlockedAt: DateTime(2024, 2, 20),
    ),
    AchievementModel(
      id: 'ach-4',
      title: 'Quiz Master',
      description: 'Complete 25 quizzes.',
      iconUrl: 'assets/achievements/quiz_master.png',
      category: AchievementCategory.mastery,
      progressCurrent: 25,
      progressTarget: 25,
      isUnlocked: true,
      unlockedAt: DateTime(2024, 3, 5),
    ),
    AchievementModel(
      id: 'ach-5',
      title: 'Top of the Class',
      description: 'Reach rank 1 on the weekly leaderboard.',
      iconUrl: 'assets/achievements/top_class.png',
      category: AchievementCategory.social,
      progressCurrent: 1,
      progressTarget: 1,
      isUnlocked: true,
      unlockedAt: DateTime(2024, 3, 12),
    ),
    const AchievementModel(
      id: 'ach-6',
      title: 'Month Marathon',
      description: 'Maintain a 30-day streak.',
      iconUrl: 'assets/achievements/month_marathon.png',
      category: AchievementCategory.consistency,
      progressCurrent: 21,
      progressTarget: 30,
      isUnlocked: false,
    ),
    const AchievementModel(
      id: 'ach-7',
      title: 'Subject Specialist',
      description: 'Score above 90% in 10 quizzes of the same subject.',
      iconUrl: 'assets/achievements/specialist.png',
      category: AchievementCategory.mastery,
      progressCurrent: 6,
      progressTarget: 10,
      isUnlocked: false,
    ),
    const AchievementModel(
      id: 'ach-8',
      title: 'Social Learner',
      description: 'Help 5 classmates through the chat feature.',
      iconUrl: 'assets/achievements/social_learner.png',
      category: AchievementCategory.social,
      progressCurrent: 2,
      progressTarget: 5,
      isUnlocked: false,
    ),
    const AchievementModel(
      id: 'ach-9',
      title: 'Knowledge Explorer',
      description: 'Complete quizzes in all available subjects.',
      iconUrl: 'assets/achievements/explorer.png',
      category: AchievementCategory.exploration,
      progressCurrent: 4,
      progressTarget: 5,
      isUnlocked: false,
    ),
    const AchievementModel(
      id: 'ach-10',
      title: 'Legend',
      description: 'Earn 5000 total XP.',
      iconUrl: 'assets/achievements/legend.png',
      category: AchievementCategory.milestone,
      progressCurrent: 3510,
      progressTarget: 5000,
      isUnlocked: false,
    ),
  ];

  static final List<DailyMissionModel> _dailyMissions = [
    const DailyMissionModel(
      id: 'mission-1',
      title: 'Solve 2 quick quizzes',
      description: 'Finish two quick quizzes in any subject.',
      xpReward: 80,
      isCompleted: false,
      progressCurrent: 1,
      progressTarget: 2,
    ),
    const DailyMissionModel(
      id: 'mission-2',
      title: 'Keep your streak alive',
      description: 'Study today to maintain your streak.',
      xpReward: 40,
      isCompleted: true,
      progressCurrent: 1,
      progressTarget: 1,
    ),
    const DailyMissionModel(
      id: 'mission-3',
      title: 'Practice weak topic',
      description: 'Complete one recommended practice quiz.',
      xpReward: 60,
      isCompleted: false,
      progressCurrent: 0,
      progressTarget: 1,
    ),
  ];

  static XpProgressModel _xpProgress = const XpProgressModel(
    level: 6,
    totalXp: 3510,
    xpIntoCurrentLevel: 510,
    xpNeededForNextLevel: 600,
    weeklyXpTarget: 500,
    weeklyXpEarned: 320,
  );

  static final Set<String> _completedSubjects = {
    'mathematics',
    'physics',
    'literature',
    'history',
  };

  static TeamChallengeModel get _teamChallenge => TeamChallengeModel(
    id: 'team-1',
    title: 'Class Sprint: 2,000 XP',
    objective: 'Earn XP together before Friday.',
    progressCurrent: 1360,
    progressTarget: 2000,
    contributorCount: 17,
    endsAt: DateTime.now().add(const Duration(days: 2)),
  );

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
          text:
              'What literary device compares two things using "like" or "as"?',
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
    'history': const ExamModel(
      id: 'quiz-hist-1',
      title: 'World History Quick Quiz',
      subjectId: 'history',
      subjectName: 'History',
      durationMinutes: 10,
      questions: [
        QuestionModel(
          id: 'qh1',
          text: 'Which ancient civilization built the pyramids at Giza?',
          options: ['Mesopotamia', 'Ancient Egypt', 'Persia', 'Phoenicia'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'qh2',
          text: 'In which year did World War II end in Europe?',
          options: ['1943', '1944', '1945', '1946'],
          correctIndex: 2,
        ),
        QuestionModel(
          id: 'qh3',
          text: 'Who led the unification of Germany in the 19th century?',
          options: [
            'Otto von Bismarck',
            'Frederick the Great',
            'Kaiser Wilhelm I',
            'Metternich',
          ],
          correctIndex: 0,
        ),
        QuestionModel(
          id: 'qh4',
          text:
              'The fall of Constantinople in 1453 marked the end of which empire?',
          options: [
            'Roman Republic',
            'Byzantine Empire',
            'Ottoman Empire',
            'Holy Roman Empire',
          ],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'qh5',
          text:
              'Which explorer is credited with initiating sustained European contact with the Americas in 1492?',
          options: [
            'Vasco da Gama',
            'Christopher Columbus',
            'Ferdinand Magellan',
            'Amerigo Vespucci',
          ],
          correctIndex: 1,
        ),
      ],
    ),
    'computer-science': const ExamModel(
      id: 'quiz-cs-1',
      title: 'Computer Science Quick Quiz',
      subjectId: 'computer-science',
      subjectName: 'Computer Science',
      durationMinutes: 10,
      questions: [
        QuestionModel(
          id: 'qcs1',
          text:
              'What is the time complexity of binary search on a sorted array?',
          options: ['O(n)', 'O(log n)', 'O(n log n)', 'O(n²)'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'qcs2',
          text: 'Which data structure follows FIFO (first-in, first-out)?',
          options: ['Stack', 'Queue', 'Heap', 'Binary search tree'],
          correctIndex: 1,
        ),
        QuestionModel(
          id: 'qcs3',
          text: 'What does HTTP stand for?',
          options: [
            'HyperText Transfer Protocol',
            'High Transfer Text Protocol',
            'Hyperlink Text Transport Process',
            'Host Terminal Transfer Protocol',
          ],
          correctIndex: 0,
        ),
        QuestionModel(
          id: 'qcs4',
          text: 'In object-oriented programming, what is encapsulation?',
          options: [
            'Hiding implementation details behind an interface',
            'Creating multiple copies of a class',
            'Converting code to machine language',
            'Running code in parallel threads',
          ],
          correctIndex: 0,
        ),
        QuestionModel(
          id: 'qcs5',
          text:
              'Which algorithm design technique breaks a problem into overlapping subproblems?',
          options: [
            'Greedy',
            'Divide and conquer',
            'Dynamic programming',
            'Backtracking',
          ],
          correctIndex: 2,
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
    const BadgeModel(
      id: 'badge-midnight-disciplined',
      name: 'Midnight Discipline',
      description: 'Completed study sessions for 5 nights in a row.',
      iconUrl: 'assets/badges/midnight_discipline.png',
      xpValue: 130,
    ),
    const BadgeModel(
      id: 'badge-speed-runner',
      name: 'Speed Runner',
      description: 'Completed 5 quick quizzes in one day.',
      iconUrl: 'assets/badges/speed_runner.png',
      xpValue: 110,
    ),
    const BadgeModel(
      id: 'badge-polymath-explorer',
      name: 'Polymath Explorer',
      description: 'Completed quizzes across all tracked subjects.',
      iconUrl: 'assets/badges/polymath_explorer.png',
      xpValue: 170,
    ),
    const BadgeModel(
      id: 'badge-class-catalyst',
      name: 'Class Catalyst',
      description: 'Helped the class sprint exceed its weekly target.',
      iconUrl: 'assets/badges/class_catalyst.png',
      xpValue: 140,
    ),
  ];

  static final Map<String, List<StudentBadgeModel>> _studentBadgesById = {
    's1': [
      StudentBadgeModel(
        studentId: 's1',
        badge: _badges[0],
        awardedAt: DateTime(2026, 2, 3),
      ),
    ],
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
  Future<List<DailyMissionModel>> fetchDailyMissions() async {
    await Future<void>.delayed(_latency);
    return List<DailyMissionModel>.from(_dailyMissions);
  }

  @override
  Future<TeamChallengeModel?> fetchTeamChallenge() async {
    await Future<void>.delayed(_latency);
    return _teamChallenge;
  }

  @override
  Future<XpProgressModel> fetchXpProgress() async {
    await Future<void>.delayed(_latency);
    return _xpProgress;
  }

  @override
  Future<NextBadgeProgressModel?> fetchNextBadgeProgress() async {
    await Future<void>.delayed(_latency);
    final pending = _achievements.where((a) => !a.isUnlocked).toList();
    if (pending.isEmpty) return null;
    final next = pending.first;
    return NextBadgeProgressModel(
      badgeName: next.title,
      description: next.description,
      progressCurrent: next.progressCurrent,
      progressTarget: next.progressTarget,
      xpReward: next.xpValue,
    );
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
  Future<GamificationMutationResult> markMissionCompleted(
    String missionId,
  ) async {
    await Future<void>.delayed(_latency);
    final index = _dailyMissions.indexWhere((m) => m.id == missionId);
    if (index < 0) {
      return GamificationMutationResult(
        xpDelta: 0,
        newTotalXp: _xpProgress.totalXp,
        leveledUp: false,
        newLevel: _xpProgress.level,
      );
    }
    final mission = _dailyMissions[index];
    if (mission.isCompleted) {
      return GamificationMutationResult(
        xpDelta: 0,
        newTotalXp: _xpProgress.totalXp,
        leveledUp: false,
        newLevel: _xpProgress.level,
      );
    }

    _dailyMissions[index] = mission.copyWith(
      isCompleted: true,
      progressCurrent: mission.progressTarget,
    );
    return _applyProgressionEvent(xpDelta: mission.xpReward);
  }

  @override
  Future<GamificationMutationResult> applyQuizOutcome({
    required String quizId,
    required String subjectId,
    required ExamResultModel result,
  }) async {
    await Future<void>.delayed(_latency);
    return _applyProgressionEvent(
      xpDelta: result.xpEarned,
      quizSubjectId: subjectId,
      quizScore: result.score,
    );
  }

  @override
  Future<StreakModel> fetchStreak() async {
    await Future<void>.delayed(_latency);
    final progress = await _safeProgress();
    final now = DateTime.now();
    return StreakModel(
      currentStreak: progress.currentStreak,
      longestStreak: progress.longestStreak,
      recentDays: List.generate(
        7,
        (i) => DateTime(now.year, now.month, now.day - (6 - i)),
      ),
    );
  }

  Future<StudentProgressModel> _safeProgress() async {
    try {
      return await _progressRepository.fetchProgress();
    } catch (_) {
      return const StudentProgressModel(
        currentStreak: 0,
        longestStreak: 0,
        totalXp: 0,
        level: 1,
        levelTitle: 'Starter',
      );
    }
  }

  int _advanceMission(String missionId, {required int step}) {
    final index = _dailyMissions.indexWhere((m) => m.id == missionId);
    if (index < 0) return 0;
    final mission = _dailyMissions[index];
    if (mission.isCompleted) return 0;
    final nextProgress = (mission.progressCurrent + step).clamp(
      0,
      mission.progressTarget,
    );
    final completed = nextProgress >= mission.progressTarget;
    _dailyMissions[index] = mission.copyWith(
      progressCurrent: nextProgress,
      isCompleted: completed,
    );
    if (completed) {
      return mission.xpReward;
    }
    return 0;
  }

  bool _incrementAchievementProgress(
    String achievementId, {
    int amount = 1,
    int? forceProgressCurrent,
    bool unlockWhenTargetReached = true,
  }) {
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index < 0) return false;
    final achievement = _achievements[index];
    if (achievement.isUnlocked && forceProgressCurrent == null) return false;

    final nextProgress =
        forceProgressCurrent ??
        (achievement.progressCurrent + amount).clamp(
          0,
          achievement.progressTarget,
        );
    final shouldUnlock =
        unlockWhenTargetReached && nextProgress >= achievement.progressTarget;

    _achievements[index] = achievement.copyWith(
      progressCurrent: nextProgress,
      isUnlocked: achievement.isUnlocked || shouldUnlock,
      unlockedAt: (achievement.isUnlocked || !shouldUnlock)
          ? achievement.unlockedAt
          : DateTime.now(),
    );
    return !achievement.isUnlocked && shouldUnlock;
  }

  void _awardXp(int xp) {
    if (xp <= 0) return;
    final totalXp = _xpProgress.totalXp + xp;
    final weeklyXp = _xpProgress.weeklyXpEarned + xp;
    final xpPerLevel = _xpProgress.xpNeededForNextLevel;
    var nextLevel = _xpProgress.level;
    var intoLevel = _xpProgress.xpIntoCurrentLevel + xp;
    while (intoLevel >= xpPerLevel) {
      intoLevel -= xpPerLevel;
      nextLevel += 1;
    }

    _xpProgress = XpProgressModel(
      level: nextLevel,
      totalXp: totalXp,
      xpIntoCurrentLevel: intoLevel,
      xpNeededForNextLevel: xpPerLevel,
      weeklyXpTarget: _xpProgress.weeklyXpTarget,
      weeklyXpEarned: weeklyXp,
    );

    _incrementAchievementProgress(
      'ach-10',
      forceProgressCurrent: totalXp,
      unlockWhenTargetReached: true,
    );
  }

  GamificationMutationResult _applyProgressionEvent({
    required int xpDelta,
    String? quizSubjectId,
    double? quizScore,
  }) {
    var totalXpDelta = xpDelta;
    final beforeLevel = _xpProgress.level;
    final beforeRank = _rankOf('weekly', 's1');
    final newAchievements = <String>[];

    if (totalXpDelta > 0) {
      _awardXp(totalXpDelta);
    }

    if (quizSubjectId != null) {
      _completedSubjects.add(quizSubjectId);
      if (_incrementAchievementProgress(
        'ach-1',
        amount: 1,
        unlockWhenTargetReached: true,
      )) {
        newAchievements.add('ach-1');
      }
      if (_incrementAchievementProgress(
        'ach-7',
        amount: (quizScore ?? 0) >= 90 ? 1 : 0,
      )) {
        newAchievements.add('ach-7');
      }
      if (_incrementAchievementProgress(
        'ach-9',
        forceProgressCurrent: _completedSubjects.length,
        unlockWhenTargetReached: true,
      )) {
        newAchievements.add('ach-9');
      }
      if ((quizScore ?? 0) == 100 &&
          _incrementAchievementProgress(
            'ach-2',
            amount: 1,
            unlockWhenTargetReached: true,
          )) {
        newAchievements.add('ach-2');
      }

      final missionBonusXp =
          _advanceMission('mission-1', step: 1) +
          _advanceMission('mission-3', step: 1);
      if (missionBonusXp > 0) {
        _awardXp(missionBonusXp);
        totalXpDelta += missionBonusXp;
      }
    }

    final newBadgeIds = _applyBadgeRules(newAchievements);

    _recalculateLeaderboardsForCurrentStudent();
    final afterRank = _rankOf('weekly', 's1');

    return GamificationMutationResult(
      xpDelta: totalXpDelta,
      newTotalXp: _xpProgress.totalXp,
      leveledUp: _xpProgress.level > beforeLevel,
      newLevel: _xpProgress.level,
      newAchievementIds: newAchievements,
      newBadgeIds: newBadgeIds,
      leaderboardBeforeRank: beforeRank,
      leaderboardAfterRank: afterRank,
    );
  }

  List<String> _applyBadgeRules(List<String> newAchievementIds) {
    final unlocked = <String>[];
    if (newAchievementIds.contains('ach-3')) {
      if (_awardBadgeIfAbsent('s1', 'badge-addis-attendance')) {
        unlocked.add('badge-addis-attendance');
      }
    }
    if (newAchievementIds.contains('ach-7')) {
      if (_awardBadgeIfAbsent('s1', 'badge-ethiopian-studies')) {
        unlocked.add('badge-ethiopian-studies');
      }
    }
    if (_xpProgress.weeklyXpEarned >= 420) {
      if (_awardBadgeIfAbsent('s1', 'badge-national-exam-prep')) {
        unlocked.add('badge-national-exam-prep');
      }
    }
    if (_xpProgress.weeklyXpEarned >= 650) {
      if (_awardBadgeIfAbsent('s1', 'badge-speed-runner')) {
        unlocked.add('badge-speed-runner');
      }
    }
    if (_xpProgress.weeklyXpEarned >= 720) {
      if (_awardBadgeIfAbsent('s1', 'badge-midnight-disciplined')) {
        unlocked.add('badge-midnight-disciplined');
      }
    }
    if (_completedSubjects.contains('computer-science') &&
        _completedSubjects.contains('literature')) {
      if (_awardBadgeIfAbsent('s1', 'badge-amharic-english')) {
        unlocked.add('badge-amharic-english');
      }
    }
    if (_completedSubjects.length >= 5) {
      if (_awardBadgeIfAbsent('s1', 'badge-polymath-explorer')) {
        unlocked.add('badge-polymath-explorer');
      }
    }
    if ((_teamChallenge.progressCurrent + _xpProgress.weeklyXpEarned) >=
        _teamChallenge.progressTarget) {
      if (_awardBadgeIfAbsent('s1', 'badge-class-catalyst')) {
        unlocked.add('badge-class-catalyst');
      }
    }
    return unlocked;
  }

  bool _awardBadgeIfAbsent(String studentId, String badgeId) {
    BadgeModel? badge;
    for (final item in _badges) {
      if (item.id == badgeId) {
        badge = item;
        break;
      }
    }
    if (badge == null) return false;
    final list = _studentBadgesById.putIfAbsent(studentId, () => []);
    final exists = list.any((b) => b.badge.id == badgeId);
    if (exists) return false;
    list.add(
      StudentBadgeModel(
        studentId: studentId,
        badge: badge,
        awardedAt: DateTime.now(),
      ),
    );
    return true;
  }

  int? _rankOf(String period, String studentId) {
    final entries = _leaderboards[period] ?? const <LeaderboardEntry>[];
    for (final entry in entries) {
      if (entry.studentId == studentId) return entry.rank;
    }
    return null;
  }

  void _recalculateLeaderboardsForCurrentStudent() {
    _upsertCurrentStudentScore(
      period: 'weekly',
      points: 240 + _xpProgress.weeklyXpEarned,
    );
    _upsertCurrentStudentScore(
      period: 'monthly',
      points: 1200 + (_xpProgress.totalXp ~/ 2),
    );
  }

  void _upsertCurrentStudentScore({
    required String period,
    required int points,
  }) {
    final entries = List<LeaderboardEntry>.from(
      _leaderboards[period] ?? const <LeaderboardEntry>[],
    );
    final index = entries.indexWhere((e) => e.studentId == 's1');
    final updated = LeaderboardEntry(
      studentId: 's1',
      studentName: 'Sara Ahmed',
      rank: 0,
      points: points,
      period: period == 'weekly'
          ? LeaderboardPeriod.weekly
          : LeaderboardPeriod.monthly,
      calculatedAt: DateTime.now(),
    );

    if (index >= 0) {
      entries[index] = updated;
    } else {
      entries.add(updated);
    }

    entries.sort((a, b) => b.points.compareTo(a.points));
    _leaderboards[period] = List<LeaderboardEntry>.generate(entries.length, (
      i,
    ) {
      final e = entries[i];
      return LeaderboardEntry(
        studentId: e.studentId,
        studentName: e.studentName,
        rank: i + 1,
        points: e.points,
        avatarUrl: e.avatarUrl,
        scope: e.scope,
        period: e.period,
        calculatedAt: DateTime.now(),
      );
    });
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
