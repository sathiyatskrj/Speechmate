import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speechmate/screens/student_dash.dart';
import 'package:speechmate/core/app_strings.dart';
void main() {
  testWidgets('StudentDash renders without crashing', (WidgetTester tester) async {
    await AppStrings.load();
    await tester.pumpWidget(MaterialApp(home: StudentDash()));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(StudentDash), findsOneWidget);
  });
}