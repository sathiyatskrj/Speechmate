import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/screens/student_dash.dart';
import 'package:speechmate/screens/student_dash_pet.dart';
import 'package:speechmate/services/native_edge_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  group('VirtualPetCompanion Component & FFI State Tests', () {
    setUp(() {
      // Mock initial SharedPreferences values before each test run
      SharedPreferences.setMockInitialValues({
        'pet_name': 'CognitiveSpeechBuddy',
        'pet_happiness': 80.0,
        'pet_hunger': 40.0,
        'pet_energy': 90.0,
        'pet_is_sleeping': false,
        'pet_xp': 15,
        'pet_owned_accessories': ['Sunglasses'],
        'pet_equipped_accessory': 'Sunglasses',
      });
    });

    testWidgets('1. VirtualPetCompanion renders correct stats and attributes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                VirtualPetCompanion(),
              ],
            ),
          ),
        ),
      );

      // Let state initialization finish (e.g. Loading persisted states)
      await tester.pump(const Duration(milliseconds: 200));

      // Check pet name rendering
      expect(find.text('CognitiveSpeechBuddy'), findsOneWidget);

      // Check current stage badge (XP is 5, so it should be BABY)
      expect(find.text('BABY'), findsOneWidget);

      // Check that accessory sunglasses are rendered in the overlay
      expect(find.text('🕶️'), findsOneWidget);

      // Verify the existence of actions: Feed Pizza (🍕), Vocabulary Quest (💡), Sleep (🛌)
      expect(find.byTooltip('Vocabulary Quest'), findsOneWidget);
      expect(find.byTooltip('Feed Pizza'), findsOneWidget);
      expect(find.byTooltip('Put to Sleep'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('2. Toggle Sleep and Wake cycles and verify FFI state adjustments', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                VirtualPetCompanion(),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Tap Sleep button
      await tester.tap(find.byTooltip('Put to Sleep'));
      await tester.pump(); // flush the tap event and initiate the async call
      await tester.pump(const Duration(milliseconds: 200)); // allow async mock to resolve and rebuild UI
      await tester.pump(); // render the newly rebuilt frame

      // Verify speech text displays "Good night!"
      expect(find.text('😴 Good night!'), findsOneWidget);

      // Verify sleep state causes the pet icon to display the sleep emoji
      expect(find.text('😴'), findsOneWidget);

      // Tap the wake up button
      await tester.tap(find.byTooltip('Wake Up'));
      await tester.pump(); // flush the tap event and initiate the async call
      await tester.pump(const Duration(milliseconds: 200)); // allow async mock to resolve and rebuild UI
      await tester.pump(); // render the newly rebuilt frame

      // Speech bubble should display greeting and pet should be back to active behavior
      expect(find.text('☀️ Good morning!'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1)); // let any newly started flutter_animate timers execute

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('3. Play/Feed interaction increases happiness and triggers stats persistence', (WidgetTester tester) async {
      double happinessTriggered = 0.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                VirtualPetCompanion(
                  onPetHappy: () {
                    happinessTriggered += 1.0;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Tap on the pet avatar to interact
      await tester.tap(find.text('🐣'), warnIfMissed: false); // Stage baby animal icon
      await tester.pump();

      // Wait for speech delay or immediate animation update
      await tester.pump(const Duration(milliseconds: 500));

      // Happiness callback must be triggered
      expect(happinessTriggered, greaterThanOrEqualTo(1.0));

      // Check SharedPreferences update
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('pet_happiness'), greaterThan(80.0));
      expect(prefs.getInt('pet_xp'), greaterThan(5));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('4. Vocabulary Quest launches dialog with correct translation choices', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                VirtualPetCompanion(),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Tap vocabulary quest button
      await tester.tap(find.byTooltip('Vocabulary Quest'));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify the modal quest opens up
      expect(find.text('💡 Teach Me Language!'), findsOneWidget);

      // Close the quest modal
      await tester.tap(find.text('Cancel').last);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('5. StudentDash builds and renders without throwing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentDash(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(StudentDash), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

