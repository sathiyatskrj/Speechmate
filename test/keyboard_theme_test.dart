import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speechmate/widgets/nicobarese_inapp_keyboard.dart';

void main() {
  group('NicobareseInAppKeyboard Widget Tests', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('Renders dedicated Nicobarese keys successfully', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NicobareseInAppKeyboard(controller: controller),
        ),
      ));

      // Verify specialized vowel keys render
      expect(find.text('ä'), findsOneWidget);
      expect(find.text('ö'), findsOneWidget);
      expect(find.text('ë'), findsOneWidget);
      expect(find.text('ṅ'), findsOneWidget);
      expect(find.text('·'), findsOneWidget);
    });

    testWidgets('Tapping keys inserts lowercase letters by default', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NicobareseInAppKeyboard(controller: controller),
        ),
      ));

      // Tap key 'ä'
      await tester.tap(find.text('ä'));
      await tester.pump();
      expect(controller.text, equals('ä'));

      // Tap key 'ö'
      await tester.tap(find.text('ö'));
      await tester.pump();
      expect(controller.text, equals('äö'));
    });

    testWidgets('Tapping Shift changes key labels to uppercase', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NicobareseInAppKeyboard(controller: controller),
        ),
      ));

      // Locate shift icon button
      final shiftFinder = find.byIcon(Icons.arrow_upward_rounded);
      expect(shiftFinder, findsOneWidget);

      await tester.tap(shiftFinder);
      await tester.pump();

      // Tap 'ä' key (label will be converted to uppercase)
      await tester.tap(find.text('Ä'));
      await tester.pump();
      expect(controller.text, equals('Ä'));
    });

    testWidgets('Backspace key removes characters correctly', (WidgetTester tester) async {
      controller.text = 'äöë';
      controller.selection = const TextSelection.collapsed(offset: 3);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NicobareseInAppKeyboard(controller: controller),
        ),
      ));

      final backspaceFinder = find.byIcon(Icons.backspace_rounded);
      expect(backspaceFinder, findsOneWidget);

      await tester.tap(backspaceFinder);
      await tester.pump();
      expect(controller.text, equals('äö'));
    });
  });
}
