// Preservation Property Tests — Property 2: Light Mode Appearance Unchanged
//
// **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8**
//
// PURPOSE: These tests MUST PASS on unfixed code.
// They establish the baseline light-mode behavior that must be preserved
// after the dark-mode fix is applied.
//
// OBSERVATION (on unfixed code with ThemeData.light()):
//   - colorScheme.surfaceContainerLowest resolves to a near-white color
//     visually equivalent to Color(0xFFF5F7FA) — both are light surfaces
//   - colorScheme.onSurface resolves to a near-black color
//     visually equivalent to AppColors.textPrimary (Color(0xFF202124))
//   - Brand accent colors (AppColors.primary, secondary, error, success)
//     are hardcoded constants — they are identical in both themes
//   - ElevatedButton foreground Colors.white on colored buttons is intentional
//   - Non-color properties (padding, border radius, font size, font weight)
//     are unaffected by theme changes

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

// ─── Brand accent colors that must remain unchanged in both themes ─────────
const Color _brandPrimary = AppColors.primary;
const Color _brandSecondary = AppColors.secondary;
const Color _brandError = AppColors.error;
const Color _brandSuccess = AppColors.success;
const Color _brandWarning = AppColors.warning;

// ─── Luminance threshold: a "light" color has relative luminance > 0.5 ────
// Colors.white has luminance 1.0; Color(0xFFF5F7FA) has luminance ~0.96.
// Dark theme surfaces have luminance < 0.1.
const double _lightLuminanceThreshold = 0.5;

// ─── Helper: pump a screen inside a light MaterialApp ─────────────────────
Future<ThemeData> _pumpLight(WidgetTester tester, Widget screen) async {
  final theme = ThemeData.light();
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: screen,
    ),
  );
  await tester.pump();
  return theme;
}

// ─── Helper: find the Scaffold widget ─────────────────────────────────────
Scaffold _findScaffold(WidgetTester tester) {
  return tester.widget<Scaffold>(find.byType(Scaffold).first);
}

// ─── Helper: check if a color is "light" (high luminance) ─────────────────
bool _isLightColor(Color color) {
  return color.computeLuminance() > _lightLuminanceThreshold;
}

// ─── Helper: check if a color is "dark" (low luminance) ───────────────────
bool _isDarkColor(Color color) {
  return color.computeLuminance() < _lightLuminanceThreshold;
}

// ─── Helper: collect all ElevatedButton styles in the widget tree ─────────
List<ButtonStyle?> _findElevatedButtonStyles(WidgetTester tester) {
  final buttons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
  return buttons.map((b) => b.style).toList();
}

// ─── All 12 affected screens with their constructors ──────────────────────
List<Widget> _allScreens() {
  return [
    const ParentResultsScreen(),
    const ParentStudentInfoScreen(childName: 'Test Child'),
    const ParentSubjectListScreen(studentId: 'test-id', childName: 'Test Child'),
    const ParentSubjectDetailScreen(
      studentId: 'test-id',
      subjectId: 'subj-id',
      subjectName: 'Mathematics',
    ),
    const ParentTeachersScreen(studentId: 'test-id', childName: 'Test Child'),
    const ParentAttendanceScreen(childName: 'Test Child'),
    const ParentAttendanceByDayScreen(
      studentId: 'test-id',
      date: '2024-01-15',
      childName: 'Test Child',
    ),
    const ParentMessageViewScreen(
      conversationId: 'conv-id',
      teacherName: 'Test Teacher',
    ),
    const ParentChildConversationViewScreen(
      studentId: 'test-id',
      conversationId: 'conv-id',
      conversationTitle: 'Test Conversation',
      childName: 'Test Child',
    ),
    const ParentChildChatHistoryScreen(
      studentId: 'test-id',
      childName: 'Test Child',
    ),
    const ParentFeedbackScreen(),
    const WeeklyReportScreen(childName: 'Test Child'),
  ];
}

// ─── Screen names for readable test output ────────────────────────────────
List<String> _screenNames() {
  return [
    'ParentResultsScreen',
    'ParentStudentInfoScreen',
    'ParentSubjectListScreen',
    'ParentSubjectDetailScreen',
    'ParentTeachersScreen',
    'ParentAttendanceScreen',
    'ParentAttendanceByDayScreen',
    'ParentMessageViewScreen',
    'ParentChildConversationViewScreen',
    'ParentChildChatHistoryScreen',
    'ParentFeedbackScreen',
    'WeeklyReportScreen',
  ];
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // PROPERTY 2a: Scaffold background is a LIGHT surface in light mode
  //
  // For all light-mode ThemeData instances, the scaffold background resolves
  // to a light surface color (high luminance, not a dark color).
  //
  // OBSERVATION: On unfixed code, scaffold.backgroundColor is hardcoded to
  // Color(0xFFF5F7FA) or Color(0xFFF0F4F8) — both are near-white (luminance ~0.96).
  // After the fix, it will be colorScheme.surfaceContainerLowest which in
  // ThemeData.light() also resolves to a near-white color.
  // Either way, in light mode the scaffold background MUST be a light color.
  // ─────────────────────────────────────────────────────────────────────────

  group('Property 2a: Scaffold background is light in light mode', () {
    final screens = _allScreens();
    final names = _screenNames();

    for (int i = 0; i < screens.length; i++) {
      final screen = screens[i];
      final name = names[i];

      testWidgets('$name scaffold background is a light color in light mode',
          (tester) async {
        await _pumpLight(tester, screen);
        final scaffold = _findScaffold(tester);

        final bg = scaffold.backgroundColor;
        // The scaffold background must be set (not null) and must be a light color
        expect(
          bg,
          isNotNull,
          reason: '$name scaffold.backgroundColor should not be null in light mode',
        );
        expect(
          _isLightColor(bg!),
          isTrue,
          reason: '$name scaffold background $bg has luminance '
              '${bg.computeLuminance().toStringAsFixed(3)} — '
              'expected a light color (luminance > $_lightLuminanceThreshold) in light mode',
        );
      });
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PROPERTY 2b: Text colors are high-contrast dark-on-light in light mode
  //
  // For all light-mode ThemeData instances, text colors resolve to
  // high-contrast dark-on-light values (low luminance, readable on white).
  //
  // OBSERVATION: On unfixed code, AppBar title and body text use
  // AppColors.textPrimary (Color(0xFF202124)) — a near-black color with
  // luminance ~0.013. After the fix, colorScheme.onSurface in ThemeData.light()
  // also resolves to a near-black color. Either way, text must be dark in light mode.
  // ─────────────────────────────────────────────────────────────────────────

  group('Property 2b: Text colors are dark (high-contrast) in light mode', () {
    testWidgets(
        'ParentResultsScreen AppBar title text is dark in light mode',
        (tester) async {
      await _pumpLight(tester, const ParentResultsScreen());
      // Find the AppBar title text — it should be a dark color
      final texts = tester.widgetList<Text>(find.byType(Text));
      bool foundDarkAppBarText = false;
      for (final text in texts) {
        final color = text.style?.color;
        if (color != null && _isDarkColor(color)) {
          foundDarkAppBarText = true;
          break;
        }
      }
      expect(
        foundDarkAppBarText,
        isTrue,
        reason: 'ParentResultsScreen should have at least one dark text color '
            'in light mode (AppBar title, section labels, etc.)',
      );
    });

    testWidgets(
        'ParentFeedbackScreen text colors are dark in light mode',
        (tester) async {
      await _pumpLight(tester, const ParentFeedbackScreen());
      final texts = tester.widgetList<Text>(find.byType(Text));
      bool foundDarkText = false;
      for (final text in texts) {
        final color = text.style?.color;
        if (color != null && _isDarkColor(color)) {
          foundDarkText = true;
          break;
        }
      }
      expect(
        foundDarkText,
        isTrue,
        reason: 'ParentFeedbackScreen should have dark text colors in light mode',
      );
    });

    testWidgets(
        'WeeklyReportScreen text colors are dark in light mode',
        (tester) async {
      await _pumpLight(tester, const WeeklyReportScreen(childName: 'Test Child'));
      final texts = tester.widgetList<Text>(find.byType(Text));
      bool foundDarkText = false;
      for (final text in texts) {
        final color = text.style?.color;
        if (color != null && _isDarkColor(color)) {
          foundDarkText = true;
          break;
        }
      }
      expect(
        foundDarkText,
        isTrue,
        reason: 'WeeklyReportScreen should have dark text colors in light mode',
      );
    });

    testWidgets(
        'ParentAttendanceScreen text colors are dark in light mode',
        (tester) async {
      await _pumpLight(tester, const ParentAttendanceScreen(childName: 'Test Child'));
      final texts = tester.widgetList<Text>(find.byType(Text));
      bool foundDarkText = false;
      for (final text in texts) {
        final color = text.style?.color;
        if (color != null && _isDarkColor(color)) {
          foundDarkText = true;
          break;
        }
      }
      expect(
        foundDarkText,
        isTrue,
        reason: 'ParentAttendanceScreen should have dark text colors in light mode',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PROPERTY 2c: Brand accent colors are unchanged in both themes
  //
  // AppColors.primary, AppColors.secondary, AppColors.error, AppColors.success,
  // and AppColors.warning are compile-time constants. They must appear unchanged
  // in the widget tree regardless of the active theme.
  //
  // This property verifies that the brand colors are present in the widget tree
  // in light mode (confirming they are used and not accidentally removed).
  // ─────────────────────────────────────────────────────────────────────────

  group('Property 2c: Brand accent colors are present and unchanged in light mode', () {
    // Verify brand color constants have not changed
    test('AppColors.primary is the expected brand blue', () {
      expect(AppColors.primary, equals(const Color(0xFF0F6FFF)));
    });

    test('AppColors.secondary is the expected brand green', () {
      expect(AppColors.secondary, equals(const Color(0xFF00B894)));
    });

    test('AppColors.error is the expected brand red', () {
      expect(AppColors.error, equals(const Color(0xFFEF4444)));
    });

    test('AppColors.success is the expected brand green', () {
      expect(AppColors.success, equals(const Color(0xFF22C55E)));
    });

    test('AppColors.warning is the expected brand amber', () {
      expect(AppColors.warning, equals(const Color(0xFFF59E0B)));
    });

    testWidgets(
        'ParentResultsScreen contains brand primary color in light mode',
        (tester) async {
      await _pumpLight(tester, const ParentResultsScreen());
      // Brand primary should appear in icons, avatars, or buttons
      bool foundPrimary = false;
      for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
        if (icon.color == _brandPrimary) {
          foundPrimary = true;
          break;
        }
      }
      if (!foundPrimary) {
        // Also check Text widgets for primary color
        for (final text in tester.widgetList<Text>(find.byType(Text))) {
          if (text.style?.color == _brandPrimary) {
            foundPrimary = true;
            break;
          }
        }
      }
      // Brand primary must appear somewhere in the screen
      expect(
        foundPrimary,
        isTrue,
        reason: 'ParentResultsScreen should use AppColors.primary '
            '(${_brandPrimary.value.toRadixString(16)}) in light mode',
      );
    });

    testWidgets(
        'ParentFeedbackScreen contains brand primary color in light mode',
        (tester) async {
      await _pumpLight(tester, const ParentFeedbackScreen());
      bool foundPrimary = false;
      for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
        if (icon.color == _brandPrimary) {
          foundPrimary = true;
          break;
        }
      }
      if (!foundPrimary) {
        for (final text in tester.widgetList<Text>(find.byType(Text))) {
          if (text.style?.color == _brandPrimary) {
            foundPrimary = true;
            break;
          }
        }
      }
      expect(
        foundPrimary,
        isTrue,
        reason: 'ParentFeedbackScreen should use AppColors.primary in light mode',
      );
    });

    testWidgets(
        'WeeklyReportScreen contains brand secondary color in light mode',
        (tester) async {
      await _pumpLight(tester, const WeeklyReportScreen(childName: 'Test Child'));
      bool foundSecondary = false;
      for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
        if (icon.color == _brandSecondary) {
          foundSecondary = true;
          break;
        }
      }
      expect(
        foundSecondary,
        isTrue,
        reason: 'WeeklyReportScreen should use AppColors.secondary '
            '(attendance icon) in light mode',
      );
    });

    testWidgets(
        'ParentStudentInfoScreen contains brand primary and secondary colors in light mode',
        (tester) async {
      await _pumpLight(
          tester, const ParentStudentInfoScreen(childName: 'Test Child'));
      bool foundBrandColor = false;
      for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
        if (icon.color == _brandPrimary || icon.color == _brandSecondary) {
          foundBrandColor = true;
          break;
        }
      }
      if (!foundBrandColor) {
        for (final text in tester.widgetList<Text>(find.byType(Text))) {
          if (text.style?.color == _brandPrimary ||
              text.style?.color == _brandSecondary) {
            foundBrandColor = true;
            break;
          }
        }
      }
      expect(
        foundBrandColor,
        isTrue,
        reason: 'ParentStudentInfoScreen should use brand colors in light mode',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PROPERTY 2d: ElevatedButton with colored backgroundColor uses
  //              Colors.white as foregroundColor (intentional white-on-color)
  //
  // Screens use patterns like:
  //   ElevatedButton.styleFrom(
  //     backgroundColor: AppColors.primary,
  //     foregroundColor: Colors.white,
  //   )
  // This white-on-color pattern is intentional and must be preserved.
  // ─────────────────────────────────────────────────────────────────────────

  group('Property 2d: ElevatedButton white-on-color pattern preserved in light mode', () {
    testWidgets(
        'ParentResultsScreen ElevatedButton with colored bg uses white foreground',
        (tester) async {
      await _pumpLight(tester, const ParentResultsScreen());
      final styles = _findElevatedButtonStyles(tester);
      for (final style in styles) {
        if (style == null) continue;
        final bgColor = style.backgroundColor?.resolve({});
        final fgColor = style.foregroundColor?.resolve({});
        if (bgColor != null && bgColor != Colors.transparent) {
          // If the button has a non-transparent background color that is
          // a brand/accent color (not white/grey), the foreground should be white
          final bgLuminance = bgColor.computeLuminance();
          if (bgLuminance < _lightLuminanceThreshold) {
            // Dark background (brand color) — foreground should be white
            expect(
              fgColor,
              equals(Colors.white),
              reason: 'ElevatedButton with dark background $bgColor '
                  'should use Colors.white as foregroundColor '
                  '(intentional white-on-color pattern)',
            );
          }
        }
      }
    });

    testWidgets(
        'ParentFeedbackScreen submit ElevatedButton uses white foreground on primary bg',
        (tester) async {
      await _pumpLight(tester, const ParentFeedbackScreen());
      final styles = _findElevatedButtonStyles(tester);
      bool foundWhiteOnColor = false;
      for (final style in styles) {
        if (style == null) continue;
        final bgColor = style.backgroundColor?.resolve({});
        final fgColor = style.foregroundColor?.resolve({});
        if (bgColor != null &&
            bgColor.computeLuminance() < _lightLuminanceThreshold &&
            fgColor == Colors.white) {
          foundWhiteOnColor = true;
          break;
        }
      }
      expect(
        foundWhiteOnColor,
        isTrue,
        reason: 'ParentFeedbackScreen should have at least one ElevatedButton '
            'with a colored background and white foreground',
      );
    });

    testWidgets(
        'WeeklyReportScreen ElevatedButton uses white foreground on colored bg',
        (tester) async {
      await _pumpLight(tester, const WeeklyReportScreen(childName: 'Test Child'));
      final styles = _findElevatedButtonStyles(tester);
      for (final style in styles) {
        if (style == null) continue;
        final bgColor = style.backgroundColor?.resolve({});
        final fgColor = style.foregroundColor?.resolve({});
        if (bgColor != null &&
            bgColor.computeLuminance() < _lightLuminanceThreshold) {
          expect(
            fgColor,
            equals(Colors.white),
            reason: 'WeeklyReportScreen ElevatedButton with dark background '
                '$bgColor should use Colors.white foreground',
          );
        }
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PROPERTY 2e: Non-color properties are identical in light mode
  //              (padding, border radius, font size, font weight)
  //
  // These properties are not affected by theme changes. We verify that
  // the screens render with the expected structural properties in light mode,
  // establishing a baseline that must be preserved after the fix.
  // ─────────────────────────────────────────────────────────────────────────

  group('Property 2e: Non-color properties preserved in light mode', () {
    testWidgets(
        'ParentResultsScreen renders with expected padding in light mode',
        (tester) async {
      await _pumpLight(tester, const ParentResultsScreen());
      // The body uses SingleChildScrollView with padding: EdgeInsets.all(16)
      // Verify the screen renders without errors (structural integrity)
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      // Verify padding containers exist
      final paddings = tester.widgetList<Padding>(find.byType(Padding));
      expect(paddings.isNotEmpty, isTrue,
          reason: 'ParentResultsScreen should have padding widgets');
    });

    testWidgets(
        'ParentFeedbackScreen renders with expected border radius in light mode',
        (tester) async {
      await _pumpLight(tester, const ParentFeedbackScreen());
      // Verify containers with border radius exist
      final containers = tester.widgetList<Container>(find.byType(Container));
      bool foundRoundedContainer = false;
      for (final container in containers) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration) {
          final borderRadius = decoration.borderRadius;
          if (borderRadius != null) {
            foundRoundedContainer = true;
            break;
          }
        }
      }
      expect(
        foundRoundedContainer,
        isTrue,
        reason: 'ParentFeedbackScreen should have containers with border radius',
      );
    });

    testWidgets(
        'WeeklyReportScreen renders with expected font sizes in light mode',
        (tester) async {
      await _pumpLight(tester, const WeeklyReportScreen(childName: 'Test Child'));
      // Verify text widgets with explicit font sizes exist
      final texts = tester.widgetList<Text>(find.byType(Text));
      bool foundStyledText = false;
      for (final text in texts) {
        if (text.style?.fontSize != null) {
          foundStyledText = true;
          // Font sizes should be reasonable (8–48 px range)
          expect(
            text.style!.fontSize!,
            inInclusiveRange(8.0, 48.0),
            reason: 'Text font size ${text.style!.fontSize} should be in '
                'the expected range (8–48 px)',
          );
        }
      }
      expect(
        foundStyledText,
        isTrue,
        reason: 'WeeklyReportScreen should have text with explicit font sizes',
      );
    });

    testWidgets(
        'ParentStudentInfoScreen renders with expected font weights in light mode',
        (tester) async {
      await _pumpLight(
          tester, const ParentStudentInfoScreen(childName: 'Test Child'));
      // Verify bold text exists (section labels, student name)
      final texts = tester.widgetList<Text>(find.byType(Text));
      bool foundBoldText = false;
      for (final text in texts) {
        if (text.style?.fontWeight == FontWeight.bold ||
            text.style?.fontWeight == FontWeight.w700 ||
            text.style?.fontWeight == FontWeight.w600) {
          foundBoldText = true;
          break;
        }
      }
      expect(
        foundBoldText,
        isTrue,
        reason: 'ParentStudentInfoScreen should have bold text '
            '(section labels, student name)',
      );
    });

    testWidgets(
        'ParentAttendanceScreen renders with expected structure in light mode',
        (tester) async {
      await _pumpLight(
          tester, const ParentAttendanceScreen(childName: 'Test Child'));
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      // Verify the screen has a body with scrollable content
      expect(
        find.byType(SingleChildScrollView).evaluate().isNotEmpty ||
            find.byType(ListView).evaluate().isNotEmpty ||
            find.byType(CustomScrollView).evaluate().isNotEmpty ||
            find.byType(Column).evaluate().isNotEmpty,
        isTrue,
        reason: 'ParentAttendanceScreen should have scrollable or column content',
      );
    });

    testWidgets(
        'All 12 screens render without errors in light mode (structural integrity)',
        (tester) async {
      final screens = _allScreens();
      final names = _screenNames();

      for (int i = 0; i < screens.length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: screens[i],
          ),
        );
        await tester.pump();

        // Each screen must render a Scaffold and AppBar without throwing
        expect(
          find.byType(Scaffold),
          findsAtLeastNWidgets(1),
          reason: '${names[i]} should render a Scaffold in light mode',
        );
        expect(
          find.byType(AppBar),
          findsAtLeastNWidgets(1),
          reason: '${names[i]} should render an AppBar in light mode',
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PROPERTY 2f: Light mode scaffold background is visually equivalent to
  //              the original hardcoded Color(0xFFF5F7FA)
  //
  // OBSERVATION: Color(0xFFF5F7FA) has luminance ~0.960.
  // ThemeData.light().colorScheme.surfaceContainerLowest also resolves to
  // a near-white color. Both are "light" by any reasonable definition.
  // We verify that the scaffold background in light mode is within the
  // "near-white" range (luminance > 0.85) — visually equivalent.
  // ─────────────────────────────────────────────────────────────────────────

  group('Property 2f: Scaffold background is near-white in light mode', () {
    const double _nearWhiteThreshold = 0.85;

    final screens = _allScreens();
    final names = _screenNames();

    for (int i = 0; i < screens.length; i++) {
      final screen = screens[i];
      final name = names[i];

      testWidgets(
          '$name scaffold background is near-white (luminance > $_nearWhiteThreshold) in light mode',
          (tester) async {
        await _pumpLight(tester, screen);
        final scaffold = _findScaffold(tester);
        final bg = scaffold.backgroundColor;

        expect(
          bg,
          isNotNull,
          reason: '$name scaffold.backgroundColor should not be null',
        );
        expect(
          bg!.computeLuminance(),
          greaterThan(_nearWhiteThreshold),
          reason: '$name scaffold background $bg has luminance '
              '${bg.computeLuminance().toStringAsFixed(3)} — '
              'expected near-white (luminance > $_nearWhiteThreshold) in light mode. '
              'Original hardcoded Color(0xFFF5F7FA) has luminance ~0.960.',
        );
      });
    }
  });
}
