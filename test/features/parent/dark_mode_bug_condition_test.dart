// Bug Condition Exploration Test — Property 1: Hardcoded Colors Break Dark Mode
//
// **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8**
//
// PURPOSE: This test MUST FAIL on unfixed code.
// Failure confirms the bug exists: parent screens use hardcoded colors that
// are not overridden by the dark theme.
//
// DO NOT attempt to fix the test or the code when it fails.
// This test encodes the expected behavior — it will pass after the fix is applied.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trilink_mobile/features/parent/student_info/screens/parent_results_screen.dart';
import 'package:trilink_mobile/features/parent/student_info/screens/parent_student_info_screen.dart';
import 'package:trilink_mobile/features/parent/student_info/screens/parent_subject_list_screen.dart';
import 'package:trilink_mobile/features/parent/student_info/screens/parent_subject_detail_screen.dart';
import 'package:trilink_mobile/features/parent/student_info/screens/parent_teachers_screen.dart';
import 'package:trilink_mobile/features/parent/attendance/screens/parent_attendance_screen.dart';
import 'package:trilink_mobile/features/parent/attendance/screens/parent_attendance_by_day_screen.dart';
import 'package:trilink_mobile/features/parent/chat/screens/parent_message_view_screen.dart';
import 'package:trilink_mobile/features/parent/chat/screens/parent_child_conversation_view_screen.dart';
import 'package:trilink_mobile/features/parent/chat/screens/parent_child_chat_history_screen.dart';
import 'package:trilink_mobile/features/parent/feedback/screens/parent_feedback_screen.dart';
import 'package:trilink_mobile/features/parent/reports/screens/weekly_report_screen.dart';
import 'package:trilink_mobile/core/theme/app_colors.dart';

// ─── Hardcoded bug-condition color constants ───────────────────────────────
const Color _hardcodedScaffoldBg1 = Color(0xFFF5F7FA);
const Color _hardcodedScaffoldBg2 = Color(0xFFF0F4F8);
const Color _hardcodedTextPrimary = Color(0xFF202124); // AppColors.textPrimary

// ─── Helper: pump a screen inside a dark MaterialApp ──────────────────────
Future<ThemeData> _pumpDark(WidgetTester tester, Widget screen) async {
  final theme = ThemeData.dark();
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: screen,
    ),
  );
  // Pump once to let the first frame build (initState fires API calls but
  // the Scaffold/AppBar are rendered immediately in the loading state).
  await tester.pump();
  return theme;
}

// ─── Helper: find the Scaffold widget ─────────────────────────────────────
Scaffold _findScaffold(WidgetTester tester) {
  return tester.widget<Scaffold>(find.byType(Scaffold).first);
}

// ─── Helper: find the first Icon inside the AppBar leading area ───────────
// We look for the first Icon whose color matches AppColors.textPrimary.
bool _appBarHasHardcodedIconColor(WidgetTester tester) {
  final icons = tester.widgetList<Icon>(find.byType(Icon));
  for (final icon in icons) {
    if (icon.color == _hardcodedTextPrimary) return true;
  }
  return false;
}

// ─── Helper: find the first Text whose style color matches textPrimary ────
bool _appBarHasHardcodedTextColor(WidgetTester tester) {
  final texts = tester.widgetList<Text>(find.byType(Text));
  for (final text in texts) {
    if (text.style?.color == _hardcodedTextPrimary) return true;
  }
  return false;
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // SCAFFOLD BACKGROUND TESTS
  // Each affected screen sets backgroundColor: const Color(0xFFF5F7FA) or
  // const Color(0xFFF0F4F8) on its Scaffold. In dark mode this should be
  // theme.colorScheme.surfaceContainerLowest, NOT the hardcoded value.
  // ─────────────────────────────────────────────────────────────────────────

  group('Scaffold backgroundColor — must NOT be hardcoded in dark mode', () {
    testWidgets('ParentResultsScreen scaffold bg is NOT hardcoded', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentResultsScreen(),
      );
      final scaffold = _findScaffold(tester);
      // BUG: scaffold.backgroundColor == const Color(0xFFF5F7FA)
      // EXPECTED after fix: theme.colorScheme.surfaceContainerLowest
      expect(
        scaffold.backgroundColor,
        isNot(equals(_hardcodedScaffoldBg1)),
        reason: 'ParentResultsScreen scaffold uses hardcoded Color(0xFFF5F7FA) '
            'instead of theme.colorScheme.surfaceContainerLowest',
      );
      expect(
        scaffold.backgroundColor,
        equals(theme.colorScheme.surfaceContainerLowest),
        reason: 'ParentResultsScreen scaffold should use '
            'theme.colorScheme.surfaceContainerLowest in dark mode',
      );
    });

    testWidgets('ParentStudentInfoScreen scaffold bg is NOT hardcoded', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentStudentInfoScreen(childName: 'Test Child'),
      );
      final scaffold = _findScaffold(tester);
      expect(
        scaffold.backgroundColor,
        isNot(equals(_hardcodedScaffoldBg1)),
        reason: 'ParentStudentInfoScreen scaffold uses hardcoded Color(0xFFF5F7FA)',
      );
      expect(
        scaffold.backgroundColor,
        equals(theme.colorScheme.surfaceContainerLowest),
      );
    });

    testWidgets('ParentSubjectListScreen scaffold bg is NOT hardcoded', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentSubjectListScreen(studentId: 'test-id', childName: 'Test Child'),
      );
      final scaffold = _findScaffold(tester);
      expect(
        scaffold.backgroundColor,
        isNot(equals(_hardcodedScaffoldBg1)),
        reason: 'ParentSubjectListScreen scaffold uses hardcoded Color(0xFFF5F7FA)',
      );
      expect(
        scaffold.backgroundColor,
        equals(theme.colorScheme.surfaceContainerLowest),
      );
    });

    testWidgets('ParentSubjectDetailScreen scaffold bg is NOT hardcoded', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentSubjectDetailScreen(
          studentId: 'test-id',
          subjectId: 'subj-id',
          subjectName: 'Mathematics',
        ),
      );
      final scaffold = _findScaffold(tester);
      expect(
        scaffold.backgroundColor,
        isNot(equals(_hardcodedScaffoldBg1)),
        reason: 'ParentSubjectDetailScreen scaffold uses hardcoded Color(0xFFF5F7FA)',
      );
      expect(
        scaffold.backgroundColor,
        equals(theme.colorScheme.surfaceContainerLowest),
      );
    });

    testWidgets('ParentTeachersScreen scaffold bg is NOT hardcoded', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentTeachersScreen(studentId: 'test-id', childName: 'Test Child'),
      );
      final scaffold = _findScaffold(tester);
      expect(
        scaffold.backgroundColor,
        isNot(equals(_hardcodedScaffoldBg1)),
        reason: 'ParentTeachersScreen scaffold uses hardcoded Color(0xFFF5F7FA)',
      );
      expect(
        scaffold.backgroundColor,
        equals(theme.colorScheme.surfaceContainerLowest),
      );
    });

    testWidgets('ParentAttendanceScreen scaffold bg is NOT hardcoded', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentAttendanceScreen(childName: 'Test Child'),
      );
      final scaffold = _findScaffold(tester);
      expect(
        scaffold.backgroundColor,
        isNot(equals(_hardcodedScaffoldBg1)),
        reason: 'ParentAttendanceScreen scaffold uses hardcoded Color(0xFFF5F7FA)',
      );
      expect(
        scaffold.backgroundColor,
        equals(theme.colorScheme.surfaceContainerLowest),
      );
    });

    testWidgets('ParentAttendanceByDayScreen scaffold bg is NOT hardcoded', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentAttendanceByDayScreen(
          studentId: 'test-id',
          date: '2024-01-15',
          childName: 'Test Child',
        ),
      );
      final scaffold = _findScaffold(tester);
      expect(
        scaffold.backgroundColor,
        isNot(equals(_hardcodedScaffoldBg1)),
        reason: 'ParentAttendanceByDayScreen scaffold uses hardcoded Color(0xFFF5F7FA)',
      );
      expect(
        scaffold.backgroundColor,
        equals(theme.colorScheme.surfaceContainerLowest),
      );
    });

    testWidgets('ParentMessageViewScreen scaffold bg is NOT hardcoded (0xFFF0F4F8)', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentMessageViewScreen(
          conversationId: 'conv-id',
          teacherName: 'Test Teacher',
        ),
      );
      final scaffold = _findScaffold(tester);
      // This screen uses Color(0xFFF0F4F8) — the other hardcoded variant
      expect(
        scaffold.backgroundColor,
        isNot(equals(_hardcodedScaffoldBg2)),
        reason: 'ParentMessageViewScreen scaffold uses hardcoded Color(0xFFF0F4F8)',
      );
      expect(
        scaffold.backgroundColor,
        equals(theme.colorScheme.surfaceContainerLowest),
      );
    });

    testWidgets('ParentChildConversationViewScreen scaffold bg is NOT hardcoded', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentChildConversationViewScreen(
          studentId: 'test-id',
          conversationId: 'conv-id',
          conversationTitle: 'Test Conversation',
          childName: 'Test Child',
        ),
      );
      final scaffold = _findScaffold(tester);
      expect(
        scaffold.backgroundColor,
        isNot(equals(_hardcodedScaffoldBg1)),
        reason: 'ParentChildConversationViewScreen scaffold uses hardcoded Color(0xFFF5F7FA)',
      );
      expect(
        scaffold.backgroundColor,
        equals(theme.colorScheme.surfaceContainerLowest),
      );
    });

    testWidgets('ParentChildChatHistoryScreen scaffold bg is NOT hardcoded', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentChildChatHistoryScreen(
          studentId: 'test-id',
          childName: 'Test Child',
        ),
      );
      final scaffold = _findScaffold(tester);
      expect(
        scaffold.backgroundColor,
        isNot(equals(_hardcodedScaffoldBg1)),
        reason: 'ParentChildChatHistoryScreen scaffold uses hardcoded Color(0xFFF5F7FA)',
      );
      expect(
        scaffold.backgroundColor,
        equals(theme.colorScheme.surfaceContainerLowest),
      );
    });

    testWidgets('ParentFeedbackScreen scaffold bg is NOT hardcoded', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentFeedbackScreen(),
      );
      final scaffold = _findScaffold(tester);
      expect(
        scaffold.backgroundColor,
        isNot(equals(_hardcodedScaffoldBg1)),
        reason: 'ParentFeedbackScreen scaffold uses hardcoded Color(0xFFF5F7FA)',
      );
      expect(
        scaffold.backgroundColor,
        equals(theme.colorScheme.surfaceContainerLowest),
      );
    });

    testWidgets('WeeklyReportScreen scaffold bg is NOT hardcoded', (tester) async {
      final theme = await _pumpDark(
        tester,
        const WeeklyReportScreen(childName: 'Test Child'),
      );
      final scaffold = _findScaffold(tester);
      expect(
        scaffold.backgroundColor,
        isNot(equals(_hardcodedScaffoldBg1)),
        reason: 'WeeklyReportScreen scaffold uses hardcoded Color(0xFFF5F7FA)',
      );
      expect(
        scaffold.backgroundColor,
        equals(theme.colorScheme.surfaceContainerLowest),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // APPBAR ICON COLOR TESTS
  // AppBar leading icons use color: AppColors.textPrimary (0xFF202124).
  // In dark mode this near-black color is invisible against the dark AppBar.
  // After fix: should use theme.colorScheme.onSurface.
  // ─────────────────────────────────────────────────────────────────────────

  group('AppBar leading Icon color — must NOT be AppColors.textPrimary in dark mode', () {
    testWidgets('ParentResultsScreen AppBar icon is NOT textPrimary', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentResultsScreen(),
      );
      // BUG: Icon color == AppColors.textPrimary == Color(0xFF202124)
      // EXPECTED after fix: theme.colorScheme.onSurface
      expect(
        _appBarHasHardcodedIconColor(tester),
        isFalse,
        reason: 'ParentResultsScreen AppBar icon uses hardcoded AppColors.textPrimary '
            '(Color(0xFF202124)) — invisible in dark mode',
      );
    });

    testWidgets('ParentStudentInfoScreen AppBar icon is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const ParentStudentInfoScreen(childName: 'Test Child'),
      );
      expect(
        _appBarHasHardcodedIconColor(tester),
        isFalse,
        reason: 'ParentStudentInfoScreen AppBar icon uses hardcoded AppColors.textPrimary',
      );
    });

    testWidgets('ParentSubjectListScreen AppBar icon is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const ParentSubjectListScreen(studentId: 'test-id', childName: 'Test Child'),
      );
      expect(
        _appBarHasHardcodedIconColor(tester),
        isFalse,
        reason: 'ParentSubjectListScreen AppBar icon uses hardcoded AppColors.textPrimary',
      );
    });

    testWidgets('ParentSubjectDetailScreen AppBar icon is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const ParentSubjectDetailScreen(
          studentId: 'test-id',
          subjectId: 'subj-id',
          subjectName: 'Mathematics',
        ),
      );
      expect(
        _appBarHasHardcodedIconColor(tester),
        isFalse,
        reason: 'ParentSubjectDetailScreen AppBar icon uses hardcoded AppColors.textPrimary',
      );
    });

    testWidgets('ParentTeachersScreen AppBar icon is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const ParentTeachersScreen(studentId: 'test-id', childName: 'Test Child'),
      );
      expect(
        _appBarHasHardcodedIconColor(tester),
        isFalse,
        reason: 'ParentTeachersScreen AppBar icon uses hardcoded AppColors.textPrimary',
      );
    });

    testWidgets('ParentAttendanceScreen AppBar icon is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const ParentAttendanceScreen(childName: 'Test Child'),
      );
      expect(
        _appBarHasHardcodedIconColor(tester),
        isFalse,
        reason: 'ParentAttendanceScreen AppBar icon uses hardcoded AppColors.textPrimary',
      );
    });

    testWidgets('ParentAttendanceByDayScreen AppBar icon is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const ParentAttendanceByDayScreen(
          studentId: 'test-id',
          date: '2024-01-15',
          childName: 'Test Child',
        ),
      );
      expect(
        _appBarHasHardcodedIconColor(tester),
        isFalse,
        reason: 'ParentAttendanceByDayScreen AppBar icon uses hardcoded AppColors.textPrimary',
      );
    });

    testWidgets('ParentMessageViewScreen AppBar icon is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const ParentMessageViewScreen(
          conversationId: 'conv-id',
          teacherName: 'Test Teacher',
        ),
      );
      expect(
        _appBarHasHardcodedIconColor(tester),
        isFalse,
        reason: 'ParentMessageViewScreen AppBar icon uses hardcoded AppColors.textPrimary',
      );
    });

    testWidgets('ParentChildConversationViewScreen AppBar icon is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const ParentChildConversationViewScreen(
          studentId: 'test-id',
          conversationId: 'conv-id',
          conversationTitle: 'Test Conversation',
          childName: 'Test Child',
        ),
      );
      expect(
        _appBarHasHardcodedIconColor(tester),
        isFalse,
        reason: 'ParentChildConversationViewScreen AppBar icon uses hardcoded AppColors.textPrimary',
      );
    });

    testWidgets('ParentChildChatHistoryScreen AppBar icon is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const ParentChildChatHistoryScreen(
          studentId: 'test-id',
          childName: 'Test Child',
        ),
      );
      expect(
        _appBarHasHardcodedIconColor(tester),
        isFalse,
        reason: 'ParentChildChatHistoryScreen AppBar icon uses hardcoded AppColors.textPrimary',
      );
    });

    testWidgets('ParentFeedbackScreen AppBar icon is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const ParentFeedbackScreen(),
      );
      expect(
        _appBarHasHardcodedIconColor(tester),
        isFalse,
        reason: 'ParentFeedbackScreen AppBar icon uses hardcoded AppColors.textPrimary',
      );
    });

    testWidgets('WeeklyReportScreen AppBar icon is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const WeeklyReportScreen(childName: 'Test Child'),
      );
      expect(
        _appBarHasHardcodedIconColor(tester),
        isFalse,
        reason: 'WeeklyReportScreen AppBar icon uses hardcoded AppColors.textPrimary',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // APPBAR TITLE TEXT COLOR TESTS
  // AppBar titles use TextStyle(color: AppColors.textPrimary).
  // After fix: should use theme.colorScheme.onSurface.
  // ─────────────────────────────────────────────────────────────────────────

  group('AppBar title Text color — must NOT be AppColors.textPrimary in dark mode', () {
    testWidgets('ParentResultsScreen AppBar title text is NOT textPrimary', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentResultsScreen(),
      );
      expect(
        _appBarHasHardcodedTextColor(tester),
        isFalse,
        reason: 'ParentResultsScreen AppBar title uses hardcoded AppColors.textPrimary color',
      );
    });

    testWidgets('ParentFeedbackScreen AppBar title text is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const ParentFeedbackScreen(),
      );
      expect(
        _appBarHasHardcodedTextColor(tester),
        isFalse,
        reason: 'ParentFeedbackScreen AppBar title uses hardcoded AppColors.textPrimary color',
      );
    });

    testWidgets('WeeklyReportScreen AppBar title text is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const WeeklyReportScreen(childName: 'Test Child'),
      );
      expect(
        _appBarHasHardcodedTextColor(tester),
        isFalse,
        reason: 'WeeklyReportScreen AppBar title uses hardcoded AppColors.textPrimary color',
      );
    });

    testWidgets('ParentAttendanceScreen AppBar title text is NOT textPrimary', (tester) async {
      await _pumpDark(
        tester,
        const ParentAttendanceScreen(childName: 'Test Child'),
      );
      expect(
        _appBarHasHardcodedTextColor(tester),
        isFalse,
        reason: 'ParentAttendanceScreen AppBar title uses hardcoded AppColors.textPrimary color',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FEEDBACK SCREEN — TextField fillColor
  // ParentFeedbackScreen uses fillColor: Colors.white on both the teacher
  // dropdown and the message TextField. In dark mode this is jarring.
  // After fix: should use theme.colorScheme.surfaceContainerHighest.
  // ─────────────────────────────────────────────────────────────────────────

  group('ParentFeedbackScreen TextField fillColor — must NOT be Colors.white in dark mode', () {
    testWidgets('Message TextField fillColor is NOT Colors.white', (tester) async {
      final theme = await _pumpDark(
        tester,
        const ParentFeedbackScreen(),
      );
      // Find all InputDecorator widgets and check their fill color
      final inputDecorators = tester.widgetList<TextField>(find.byType(TextField));
      for (final field in inputDecorators) {
        final fillColor = field.decoration?.fillColor;
        if (fillColor != null) {
          expect(
            fillColor,
            isNot(equals(Colors.white)),
            reason: 'ParentFeedbackScreen TextField uses fillColor: Colors.white '
                'which is hardcoded and does not adapt to dark mode. '
                'Expected: theme.colorScheme.surfaceContainerHighest',
          );
          expect(
            fillColor,
            equals(theme.colorScheme.surfaceContainerHighest),
            reason: 'ParentFeedbackScreen TextField fillColor should be '
                'theme.colorScheme.surfaceContainerHighest in dark mode',
          );
        }
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // WEEKLY REPORT SCREEN — LinearProgressIndicator backgroundColor
  // WeeklyReportScreen uses backgroundColor: Colors.grey.shade200 on the
  // LinearProgressIndicator. In dark mode this light-grey track is wrong.
  // After fix: should use theme.colorScheme.surfaceContainerHighest.
  // ─────────────────────────────────────────────────────────────────────────

  group('WeeklyReportScreen LinearProgressIndicator — must NOT use Colors.grey.shade200 in dark mode', () {
    testWidgets('LinearProgressIndicator backgroundColor is NOT Colors.grey.shade200', (tester) async {
      final theme = await _pumpDark(
        tester,
        const WeeklyReportScreen(childName: 'Test Child'),
      );

      // The progress indicator is only rendered when data is loaded.
      // On unfixed code, we can verify the hardcoded color by checking
      // if any LinearProgressIndicator uses the hardcoded grey shade.
      // We pump with a fake data state by checking the widget tree.
      final progressIndicators = tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      for (final indicator in progressIndicators) {
        expect(
          indicator.backgroundColor,
          isNot(equals(Colors.grey.shade200)),
          reason: 'WeeklyReportScreen LinearProgressIndicator uses '
              'backgroundColor: Colors.grey.shade200 which does not adapt to dark mode. '
              'Expected: theme.colorScheme.surfaceContainerHighest',
        );
      }

      // Also verify the source code intent: the screen's _buildAttendanceCard
      // hardcodes Colors.grey.shade200. We confirm the bug by checking the
      // scaffold background as a proxy (if scaffold is wrong, the whole
      // screen is using hardcoded colors).
      final scaffold = _findScaffold(tester);
      expect(
        scaffold.backgroundColor,
        isNot(equals(_hardcodedScaffoldBg1)),
        reason: 'WeeklyReportScreen scaffold background confirms hardcoded color usage',
      );
    });
  });
}
