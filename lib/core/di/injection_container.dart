import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/feature_flags.dart';
import '../theme/theme_notifier.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/auth/repositories/real_auth_repository.dart';
import '../../features/student/dashboard/repositories/student_dashboard_repository.dart';
import '../../features/student/dashboard/repositories/mock_student_dashboard_repository.dart';
import '../../features/student/dashboard/repositories/real_student_dashboard_repository.dart';
import '../../features/student/grades/repositories/student_grades_repository.dart';
import '../../features/student/grades/repositories/mock_student_grades_repository.dart';
import '../../features/student/grades/repositories/real_student_grades_repository.dart';
import '../../features/student/attendance/repositories/student_attendance_repository.dart';
import '../../features/student/attendance/repositories/mock_student_attendance_repository.dart';
import '../../features/student/attendance/repositories/real_student_attendance_repository.dart';
import '../../features/student/profile/repositories/student_profile_repository.dart';
import '../../features/student/profile/repositories/mock_student_profile_repository.dart';
import '../../features/student/profile/repositories/real_student_profile_repository.dart';
import '../../features/student/assignments/repositories/student_assignments_repository.dart';
import '../../features/student/assignments/repositories/mock_student_assignments_repository.dart';
import '../../features/student/assignments/repositories/real_student_assignments_repository.dart';
import '../../features/student/chat/repositories/student_chat_repository.dart';
import '../../features/student/chat/repositories/mock_student_chat_repository.dart';
import '../../features/student/chat/repositories/real_student_chat_repository.dart';
import '../../features/student/calendar/repositories/student_calendar_repository.dart';
import '../../features/student/calendar/repositories/mock_student_calendar_repository.dart';
import '../../features/student/calendar/repositories/real_student_calendar_repository.dart';
import '../../features/student/notifications/repositories/student_notifications_repository.dart';
import '../../features/student/notifications/repositories/mock_student_notifications_repository.dart';
import '../../features/student/notifications/repositories/real_student_notifications_repository.dart';
import '../../features/student/announcements/repositories/student_announcements_repository.dart';
import '../../features/student/announcements/repositories/mock_student_announcements_repository.dart';
import '../../features/student/announcements/repositories/real_student_announcements_repository.dart';
import '../../features/student/feedback/repositories/student_feedback_repository.dart';
import '../../features/student/feedback/repositories/mock_student_feedback_repository.dart';
import '../../features/student/feedback/repositories/real_student_feedback_repository.dart';
import '../../features/student/gamification/repositories/student_gamification_repository.dart';
import '../../features/student/gamification/repositories/mock_student_gamification_repository.dart';
import '../../features/student/gamification/repositories/real_student_gamification_repository.dart';
import '../../features/student/exams/repositories/student_exams_repository.dart';
import '../../features/student/exams/repositories/mock_student_exams_repository.dart';
import '../../features/student/exams/repositories/real_student_exams_repository.dart';
import '../../features/student/courses/repositories/student_courses_repository.dart';
import '../../features/student/courses/repositories/mock_student_courses_repository.dart';
import '../../features/student/courses/repositories/real_student_courses_repository.dart';
import '../../features/student/courses/repositories/student_curriculum_repository.dart';
import '../../features/student/courses/repositories/mock_student_curriculum_repository.dart';
import '../../features/student/courses/repositories/real_student_curriculum_repository.dart';
import '../../features/student/grades/repositories/student_performance_repository.dart';
import '../../features/student/grades/repositories/mock_student_performance_repository.dart';
import '../../features/student/grades/repositories/real_student_performance_repository.dart';
import '../../features/student/sync/repositories/student_sync_repository.dart';
import '../../features/student/sync/repositories/mock_student_sync_repository.dart';
import '../../features/student/sync/repositories/real_student_sync_repository.dart';
import '../../features/student/ai_assistant/repositories/student_ai_assistant_repository.dart';
import '../../features/student/ai_assistant/repositories/mock_student_ai_assistant_repository.dart';
import '../../features/student/settings/repositories/student_settings_repository.dart';
import '../../features/student/settings/repositories/mock_student_settings_repository.dart';
import '../../features/student/settings/repositories/real_student_settings_repository.dart';
import '../../features/student/analytics/repositories/student_analytics_repository.dart';
import '../../features/student/analytics/repositories/mock_student_analytics_repository.dart';
import '../../features/student/analytics/repositories/real_student_analytics_repository.dart';
import '../../features/student/shared/repositories/student_progress_repository.dart';
import '../../features/student/shared/repositories/mock_student_progress_repository.dart';
import '../../features/student/shared/repositories/real_student_progress_repository.dart';
import '../../features/student/textbooks/repositories/textbook_repository.dart';
import '../../features/student/textbooks/repositories/mock_textbook_repository.dart';
import '../../features/student/textbooks/repositories/real_textbook_repository.dart';
import '../../features/student/textbooks/repositories/textbook_file_cache_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await Hive.initFlutter();

  // ── Core services ──
  final settingsBox = await Hive.openBox('settings');
  sl.registerLazySingleton<StorageService>(() => StorageService(settingsBox));
  final themeNotifier = ThemeNotifier(sl<StorageService>());
  ThemeNotifier.instance = themeNotifier;
  sl.registerLazySingleton<ThemeNotifier>(() => themeNotifier);
  sl.registerLazySingleton<SoundService>(
    () => SoundService(sl<StorageService>()),
  );

  // ── Auth ──
  sl.registerLazySingleton<AuthRepository>(() => RealAuthRepository());
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(repository: sl<AuthRepository>()),
  );

  // ── Student repositories ──
  final useRealStudentData = FeatureFlags.useRealApi;

  sl.registerLazySingleton<StudentDashboardRepository>(
    () => useRealStudentData
        ? RealStudentDashboardRepository(
            progressRepository: sl<StudentProgressRepository>(),
            storageService: sl<StorageService>(),
          )
        : MockStudentDashboardRepository(sl<StudentProgressRepository>()),
  );
  sl.registerLazySingleton<StudentGradesRepository>(
    () => useRealStudentData
        ? RealStudentGradesRepository()
        : MockStudentGradesRepository(),
  );
  sl.registerLazySingleton<StudentAttendanceRepository>(
    () => useRealStudentData
        ? RealStudentAttendanceRepository(storageService: sl<StorageService>())
        : MockStudentAttendanceRepository(),
  );
  sl.registerLazySingleton<StudentProfileRepository>(
    () => useRealStudentData
        ? RealStudentProfileRepository(storageService: sl<StorageService>())
        : MockStudentProfileRepository(),
  );
  sl.registerLazySingleton<StudentAssignmentsRepository>(
    () => useRealStudentData
        ? RealStudentAssignmentsRepository(
            fallback: MockStudentAssignmentsRepository(),
          )
        : MockStudentAssignmentsRepository(),
  );
  sl.registerLazySingleton<StudentChatRepository>(
    () => useRealStudentData
        ? RealStudentChatRepository(storageService: sl<StorageService>())
        : MockStudentChatRepository(),
  );
  sl.registerLazySingleton<StudentCalendarRepository>(
    () => useRealStudentData
        ? RealStudentCalendarRepository()
        : MockStudentCalendarRepository(),
  );
  sl.registerLazySingleton<StudentNotificationsRepository>(
    () => useRealStudentData
        ? RealStudentNotificationsRepository()
        : MockStudentNotificationsRepository(),
  );
  sl.registerLazySingleton<StudentAnnouncementsRepository>(
    () => useRealStudentData
        ? RealStudentAnnouncementsRepository()
        : MockStudentAnnouncementsRepository(),
  );
  sl.registerLazySingleton<StudentFeedbackRepository>(
    () => useRealStudentData
        ? RealStudentFeedbackRepository()
        : MockStudentFeedbackRepository(),
  );
  sl.registerLazySingleton<StudentGamificationRepository>(
    () => useRealStudentData
        ? RealStudentGamificationRepository(
            progressRepository: sl<StudentProgressRepository>(),
            fallback: MockStudentGamificationRepository(
              sl<StudentProgressRepository>(),
            ),
          )
        : MockStudentGamificationRepository(sl<StudentProgressRepository>()),
  );
  sl.registerLazySingleton<StudentExamsRepository>(
    () => useRealStudentData
        ? RealStudentExamsRepository()
        : MockStudentExamsRepository(),
  );
  sl.registerLazySingleton<StudentCoursesRepository>(
    () => useRealStudentData
        ? RealStudentCoursesRepository(
            textbooksRepository: sl<TextbookRepository>(),
            fallback: MockStudentCoursesRepository(),
          )
        : MockStudentCoursesRepository(),
  );
  sl.registerLazySingleton<StudentCurriculumRepository>(
    () => useRealStudentData
        ? RealStudentCurriculumRepository(
            fallback: MockStudentCurriculumRepository(),
          )
        : MockStudentCurriculumRepository(),
  );
  sl.registerLazySingleton<StudentPerformanceRepository>(
    () => useRealStudentData
        ? RealStudentPerformanceRepository()
        : MockStudentPerformanceRepository(),
  );
  sl.registerLazySingleton<StudentSyncRepository>(
    () => useRealStudentData
        ? RealStudentSyncRepository()
        : MockStudentSyncRepository(),
  );
  sl.registerLazySingleton<StudentAiAssistantRepository>(
    () => MockStudentAiAssistantRepository(),
  );
  sl.registerLazySingleton<StudentSettingsRepository>(
    () => useRealStudentData
        ? RealStudentSettingsRepository()
        : MockStudentSettingsRepository(),
  );
  sl.registerLazySingleton<StudentAnalyticsRepository>(
    () => useRealStudentData
        ? RealStudentAnalyticsRepository(storageService: sl<StorageService>())
        : MockStudentAnalyticsRepository(),
  );
  sl.registerLazySingleton<StudentProgressRepository>(
    () => useRealStudentData
        ? RealStudentProgressRepository()
        : MockStudentProgressRepository(),
  );
  sl.registerLazySingleton<TextbookRepository>(
    () => useRealStudentData
        ? RealTextbookRepository()
        : MockTextbookRepository(),
  );
  sl.registerLazySingleton<TextbookFileCacheService>(
    () => TextbookFileCacheService(storageService: sl<StorageService>()),
  );
}
