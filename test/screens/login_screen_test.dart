import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fastapi_gemini_app/screens/login_screen.dart';
import 'package:flutter_fastapi_gemini_app/services/auth_service.dart';
import 'package:mockito/mockito.dart';

import '../services/auth_service_test.mocks.dart';

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  testWidgets('LoginScreen shows widgets correctly when not logged in',
      (WidgetTester tester) async {
    when(mockAuthService.isLoggedIn()).thenAnswer((_) async => false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the AppBar title specifically.
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Login')), findsOneWidget);

    // Verify the input fields.
    expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

    // Verify the login button specifically.
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
