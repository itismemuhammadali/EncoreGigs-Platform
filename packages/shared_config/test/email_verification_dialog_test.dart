import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_config/email_verification_dialog.dart';

void main() {
  testWidgets('Initial dialog load never displays an error box even if onSendVerification returns too-many-requests', (WidgetTester tester) async {
    // Simulate onSendVerification returning a rate-limit error on initial load
    Future<String?> mockSendVerification(String email) async {
      return 'Too many attempts. Please wait a few minutes before trying again.';
    }

    Future<bool> mockCheckVerification() async {
      return false;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmailVerificationDialog(
            email: 'test@example.com',
            onVerified: () {},
            onSendVerification: mockSendVerification,
            onCheckVerification: mockCheckVerification,
          ),
        ),
      ),
    );

    // Allow initState to execute _sendVerification
    await tester.pump();

    // Verify dialog title and email are shown
    expect(find.text('Verify Your Email'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text("I've Verified"), findsOneWidget);

    // CRITICAL: Verify that the error message is NOT rendered on initial open
    expect(find.textContaining('Too many attempts'), findsNothing);
  });
}
