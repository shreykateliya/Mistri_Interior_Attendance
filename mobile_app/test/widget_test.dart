import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/login_screen.dart'; // Import your login screen

void main() {
  testWidgets('App loads Login Screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: LoginScreen(),
    ));

    // Verify that the Login button is on the screen to ensure it loaded.
    expect(find.text('LOGIN'), findsOneWidget);
  });
}