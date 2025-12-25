
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speechmate/screens/community_screen.dart';

void main() {
  testWidgets('CommunityScreen renders correctly', (WidgetTester tester) async {
    // 1. Pump the widget
    // We wrap it in a MaterialApp because CommunityScreen uses Scaffold and Theme,
    // which require a MaterialApp ancestor.
    await tester.pumpWidget(const MaterialApp(home: CommunityScreen()));

    // 2. Verify initial state
    // Check if the title "Community Hub" is present
    expect(find.text('Community Hub 🌏'), findsOneWidget);

    // Check if the "New Post" button is present
    expect(find.text('New Post'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);

    // 3. Interact with the widget
    // Tap the "Admin Panel" toggle button (second action button)
    // The icon is admin_panel_settings_outlined in default mode
    await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined));
    await tester.pump(); // Rebuild the widget after the state change

    // 4. Verify state change
    // The title should now be "Admin Panel"
    expect(find.text('Admin Panel 🛡️'), findsOneWidget);
    
    // Check for snackbar
    expect(find.text('Admin Mode Activated 🛡️'), findsOneWidget);
  });
}
