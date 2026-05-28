import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/screens/cultural_calendar_screen.dart';
import 'package:speechmate/screens/marks_entry_screen.dart';
import 'package:speechmate/screens/quiz_analytics_screen.dart';

void main() {
  group('Teacher Dashboard Offline Roster & Marks Integrations Tests', () {
    testWidgets('1. MarksEntryScreen displays tutorial banner when class roster is empty', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'class_roster': '[]', // empty roster
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarksEntryScreen(),
          ),
        ),
      );

      // Settle all animations (e.g. Slide and Fade)
      await tester.pumpAndSettle();

      // Renders onboarding/tutorial card explaining how to start
      expect(find.text('No Roster Registered 👥'), findsOneWidget);
      expect(find.text('Add Students in Class Roster'), findsOneWidget);
    });

    testWidgets('2. MarksEntryScreen loads students from Class Roster and retrieves entered marks', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'class_roster': jsonEncode([
          {'name': 'Aditya Kumar', 'class': 'Class 5', 'wordsLearned': 12, 'quizScore': 0, 'status': 'New'},
          {'name': 'Siddharth Sen', 'class': 'Class 5', 'wordsLearned': 8, 'quizScore': 0, 'status': 'New'},
        ]),
        'marks_Class 5_Weekly Quiz': jsonEncode([
          {'name': 'Aditya Kumar', 'score': '88', 'maxScore': '100'},
          {'name': 'Siddharth Sen', 'score': '42', 'maxScore': '100'},
        ]),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarksEntryScreen(),
          ),
        ),
      );

      // Settle all animations
      await tester.pumpAndSettle();

      // Should show student names
      expect(find.text('Aditya Kumar'), findsOneWidget);
      expect(find.text('Siddharth Sen'), findsOneWidget);

      // Verify text field values are loaded correctly from SharedPreferences
      expect(find.text('88'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('3. QuizAnalyticsScreen calculates real averages, counts, and priority alerts dynamically', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'class_roster': jsonEncode([
          {'name': 'Aditya Kumar', 'class': 'Class 5', 'wordsLearned': 12, 'quizScore': 0, 'status': 'New'},
          {'name': 'Siddharth Sen', 'class': 'Class 5', 'wordsLearned': 8, 'quizScore': 0, 'status': 'New'},
        ]),
        'marks_Class 5_Weekly Quiz': jsonEncode([
          {'name': 'Aditya Kumar', 'score': '95', 'maxScore': '100'},
          {'name': 'Siddharth Sen', 'score': '45', 'maxScore': '100'},
        ]),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuizAnalyticsScreen(),
          ),
        ),
      );

      // Settle all animations
      await tester.pumpAndSettle();

      // Class 5 has scores 95 and 45. Average is (95 + 45) ~/ 2 = 70.
      expect(find.text('70%'), findsWidgets); // Overall avg card shows overall avg of 70%

      // Roster counts 2 students in Class 5
      expect(find.text('2 students'), findsOneWidget);

      // Dynamic warning priority alert should be generated because 1 student scored below 50%
      expect(find.textContaining('student(s) in Class 5 scored below 50%'), findsOneWidget);
    });

    testWidgets('4. CulturalCalendarScreen lists default events and supports CRUD editing in Teacher mode', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({}); // Start fresh to seed defaults

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CulturalCalendarScreen(isTeacher: true),
          ),
        ),
      );

      // Settle all animations
      await tester.pumpAndSettle();

      // Displays standard default calendar events (e.g. Canoe Race Festival)
      expect(find.text('Canoe Race Festival'), findsOneWidget);

      // Floating Add button should be visible in teacher mode
      expect(find.text('Add Event'), findsOneWidget);

      // Verify the presence of editing button on event cards
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
    });
  });
}
