import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_utility_app/screens/auth/panel_selection_screen.dart';

void main() {
  testWidgets('shows user and admin panel options', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PanelSelectionScreen(),
      ),
    );

    expect(find.text('Personal Utility'), findsOneWidget);
    expect(find.text('User Panel'), findsOneWidget);
    expect(find.text('Admin Panel'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.admin_panel_settings_outlined), findsOneWidget);
  });
}
