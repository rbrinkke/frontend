import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_fastapi_gemini_app/models/auth_models.dart';
import 'package:flutter_fastapi_gemini_app/screens/auth/auth_screen_controller.dart';
import 'package:flutter_fastapi_gemini_app/services/auth_service.dart';

import 'auth_screen_controller_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  late MockAuthService mockAuthService;
  late AuthScreenController controller;

  setUp(() {
    mockAuthService = MockAuthService();
    controller = AuthScreenController(mockAuthService);
  });

  group('AuthScreenController Tests', () {
    // ~~~~~~~~~~~~~~~~~~~~~~ Flow and State Tests ~~~~~~~~~~~~~~~~~~~~~~
    test('Initial state is correct', () {
      expect(controller.state.flow, AuthFlow.login);
      expect(controller.state.step, AuthStep.credentials);
      expect(controller.state.isLoading, false);
      expect(controller.state.error, isNull);
    });

    test('setFlow updates the auth flow', () {
      controller.setFlow(AuthFlow.register);
      expect(controller.state.flow, AuthFlow.register);
      controller.setFlow(AuthFlow.passwordReset);
      expect(controller.state.flow, AuthFlow.passwordReset);
    });

    // ~~~~~~~~~~~~~~~~~~~~~~ submitCredentials Tests ~~~~~~~~~~~~~~~~~~~~~~
    test('submitCredentials transitions to code step on login success (code required)', () async {
      when(mockAuthService.loginStep1(any, any)).thenAnswer(
        (_) async => const LoginCodeSentResponse(
          message: 'code sent',
          email: 'test@example.com',
          userId: '123',
        ),
      );

      await controller.submitCredentials('test@example.com', 'password');

      expect(controller.state.step, AuthStep.code);
      expect(controller.state.isLoading, false);
    });

    test('submitCredentials handles login success (token received)', () async {
      when(mockAuthService.loginStep1(any, any)).thenAnswer(
        (_) async => const TokenResponse(
          accessToken: 'access',
          refreshToken: 'refresh',
        ),
      );

      await controller.submitCredentials('test@example.com', 'password');

      // In a real app, a listener would navigate to the home screen.
      // Here, we just check that the state is reset.
      expect(controller.state.step, AuthStep.credentials);
      expect(controller.state.isLoading, false);
    });

    test('submitCredentials sets error state on failure', () async {
      when(mockAuthService.loginStep1(any, any)).thenThrow(Exception('Invalid credentials'));

      await controller.submitCredentials('test@example.com', 'password');

      expect(controller.state.error, isNotNull);
      expect(controller.state.isLoading, false);
    });

    // ~~~~~~~~~~~~~~~~~~~~~~ submitCode Tests ~~~~~~~~~~~~~~~~~~~~~~
    test('submitCode handles login success', () async {
      // Set initial state to be in the code step
      controller.state = controller.state.copyWith(
        flow: AuthFlow.login,
        step: AuthStep.code,
        email: 'test@example.com',
        password: 'password',
      );

      when(mockAuthService.loginStep2(any, any, any)).thenAnswer(
        (_) async => const TokenResponse(
          accessToken: 'access',
          refreshToken: 'refresh',
        ),
      );

      await controller.submitCode('123456');

      expect(controller.state.step, AuthStep.credentials);
      expect(controller.state.isLoading, false);
    });
  });
}
