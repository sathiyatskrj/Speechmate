import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speechmate/widgets/gamification_header.dart';
import 'package:speechmate/features/gamification/gamification_service.dart';

void main() {
  group('Widget Smoke Tests', () {
    testWidgets('GamificationHeader renders without crashing', (WidgetTester tester) async {
      // Set up known static state before rendering
      GamificationService.xp = 150;
      GamificationService.currentLevel = 2;
      GamificationService.nextLevelXp = 250;
      GamificationService.currentStreak = 3;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GamificationHeader(),
          ),
        ),
      );

      // Verify level number is displayed
      expect(find.text('2'), findsOneWidget);

      // Verify level title is displayed
      expect(find.text('Seed Planter'), findsOneWidget);

      // Verify XP text is displayed
      expect(find.text('150 / 250 XP'), findsOneWidget);

      // Verify streak is displayed
      expect(find.text('3'), findsOneWidget);

      // Verify fire icon is present
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('GamificationHeader updates when static values change', (WidgetTester tester) async {
      GamificationService.xp = 500;
      GamificationService.currentLevel = 4;
      GamificationService.nextLevelXp = 850;
      GamificationService.currentStreak = 7;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GamificationHeader(),
          ),
        ),
      );

      expect(find.text('4'), findsOneWidget);
      expect(find.text('Story Teller'), findsOneWidget);
      expect(find.text('500 / 850 XP'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });
  });
}
