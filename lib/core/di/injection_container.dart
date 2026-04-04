import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/theme_notifier.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/auth/repositories/mock_auth_repository.dart';
import '../../features/student/dashboard/repositories/student_dashboard_repository.dart';
import '../../features/student/dashboard/repositories/mock_student_dashboard_repository.dart';
import '../../features/student/grades/repositories/student_grades_repository.dart';
import '../../features/student/grades/repositories/mock_student_grades_repository.dart';
import '../../features/student/attendance/repositories/student_attendance_repository.dart';
import '../../features/student/attendance/repositories/mock_student_attendance_repository.dart';
import '../../features/student/profile/repositories/student_profile_repository.dart';
import '../../features/student/profile/repositories/mock_student_profile_repository.dart';
import '../../features/student/assignments/repositories/student_assignments_repository.dart';
import '../../features/student/assignments/repositories/mock_student_assignments_repository.dart';
import '../../features/student/chat/repositories/student_chat_repository.dart';
import '../../features/student/chat/repositories/mock_student_chat_repository.dart';
import '../../features/student/calendar/repositories/student_calendar_repository.dart';
import '../../features/student/calendar/repositories/mock_student_calendar_repository.dart';
import '../../features/student/notifications/repositories/student_notifications_repository.dart';
import '../../features/student/notifications/repositories/mock_student_notifications_repository.dart';
import '../../features/student/announcements/repositories/student_announcements_repository.dart';
import '../../features/student/announcements/repositories/mock_student_announcements_repository.dart';
import '../../features/student/feedback/repositories/student_feedback_repository.dart';
import '../../features/student/feedback/repositories/mock_student_feedback_repository.dart';
import '../../features/student/gamification/repositories/student_gamification_repository.dart';
import '../../features/student/gamification/repositories/mock_student_gamification_repository.dart';
import '../../features/student/exams/repositories/student_exams_repository.dart';
import '../../features/student/exams/repositories/mock_student_exams_repository.dart';
import '../../features/student/courses/repositories/student_courses_repository.dart';
import '../../features/student/courses/repositories/mock_student_courses_repository.dart';
import '../../features/student/courses/repositories/student_curriculum_repository.dart';
import '../../features/student/courses/repositories/mock_student_curriculum_repository.dart';
import '../../features/student/grades/repositories/student_performance_repository.dart';
import '../../features/student/grades/repositories/mock_student_performance_repository.dart';
import '../../features/student/sync/repositories/student_sync_repository.dart';
import '../../features/student/sync/repositories/mock_student_sync_repository.dart';
import '../../features/student/ai_assistant/repositories/student_ai_assistant_repository.dart';
import '../../features/student/ai_assistant/repositories/mock_student_ai_assistant_repository.dart';
import '../../features/student/shared/repositories/student_progress_repository.dart';
import '../../features/student/shared/repositories/mock_student_progress_repository.dart';

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
  sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(repository: sl<AuthRepository>()),
  );

  // ── Student repositories ──
  sl.registerLazySingleton<StudentDashboardRepository>(
    () => MockStudentDashboardRepository(sl<StudentProgressRepository>()),
  );
  sl.registerLazySingleton<StudentGradesRepository>(
    () => MockStudentGradesRepository(),
  );
  sl.registerLazySingleton<StudentAttendanceRepository>(
    () => MockStudentAttendanceRepository(),
  );
  sl.registerLazySingleton<StudentProfileRepository>(
    () => MockStudentProfileRepository(),
  );
  sl.registerLazySingleton<StudentAssignmentsRepository>(
    () => MockStudentAssignmentsRepository(),
  );
  sl.registerLazySingleton<StudentChatRepository>(
    () => MockStudentChatRepository(),
  );
  sl.registerLazySingleton<StudentCalendarRepository>(
    () => MockStudentCalendarRepository(),
  );
  sl.registerLazySingleton<StudentNotificationsRepository>(
    () => MockStudentNotificationsRepository(),
  );
  sl.registerLazySingleton<StudentAnnouncementsRepository>(
    () => MockStudentAnnouncementsRepository(),
  );
  sl.registerLazySingleton<StudentFeedbackRepository>(
    () => MockStudentFeedbackRepository(),
  );
  sl.registerLazySingleton<StudentGamificationRepository>(
    () => MockStudentGamificationRepository(sl<StudentProgressRepository>()),
  );
  sl.registerLazySingleton<StudentExamsRepository>(
    () => MockStudentExamsRepository(),
  );
  sl.registerLazySingleton<StudentCoursesRepository>(
    () => MockStudentCoursesRepository(),
  );
  sl.registerLazySingleton<StudentCurriculumRepository>(
    () => MockStudentCurriculumRepository(),
  );
  sl.registerLazySingleton<StudentPerformanceRepository>(
    () => MockStudentPerformanceRepository(),
  );
  sl.registerLazySingleton<StudentSyncRepository>(
    () => MockStudentSyncRepository(),
  );
  sl.registerLazySingleton<StudentAiAssistantRepository>(
    () => MockStudentAiAssistantRepository(),
  );
  sl.registerLazySingleton<StudentProgressRepository>(
    () => MockStudentProgressRepository(),
  );
}
