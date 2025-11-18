import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_fastapi_gemini_app/core/network/secure_storage_service.dart';
import 'package:flutter_fastapi_gemini_app/models/auth_models.dart';
import 'package:flutter_fastapi_gemini_app/services/auth_service.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([Dio, SecureStorageService])
void main() {
  late MockDio mockDio;
  late MockSecureStorageService mockStorageService;
  late AuthService authService;

  setUp(() {
    mockDio = MockDio();
    mockStorageService = MockSecureStorageService();
    authService = AuthService(dio: mockDio, storageService: mockStorageService);
  });

  group('AuthService Tests', () {
    // ~~~~~~~~~~~~~~~~~~~~~~ Login Tests ~~~~~~~~~~~~~~~~~~~~~~
    test('loginStep1 returns LoginCodeSentResponse on success', () async {
      final responseData = {
        'message': 'Verification code sent',
        'email': 'test@example.com',
        'user_id': '123',
      };
      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: responseData,
          statusCode: 200,
        ),
      );

      final result = await authService.loginStep1('test@example.com', 'password');

      expect(result, isA<LoginCodeSentResponse>());
      expect((result as LoginCodeSentResponse).email, 'test@example.com');
    });

    test('loginStep2 returns TokenResponse and saves tokens on success', () async {
      final responseData = {
        'access_token': 'access',
        'refresh_token': 'refresh',
      };
      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: responseData,
          statusCode: 200,
        ),
      );

      final result = await authService.loginStep2('test@example.com', 'password', '123456');

      expect(result, isA<TokenResponse>());
      verify(mockStorageService.saveAccessToken('access')).called(1);
      verify(mockStorageService.saveRefreshToken('refresh')).called(1);
    });

    test('loginStep2 throws DioError on failure', () async {
      when(mockDio.post(any, data: anyNamed('data'))).thenThrow(
        DioError(requestOptions: RequestOptions(path: '')),
      );

      expect(
        () => authService.loginStep2('test@example.com', 'password', 'wrong-code'),
        throwsA(isA<DioError>()),
      );
    });

    // ~~~~~~~~~~~~~~~~~~~~~~ Registration Tests ~~~~~~~~~~~~~~~~~~~~~~
    test('register completes successfully', () async {
      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 201,
        ),
      );

      await authService.register('new@example.com', 'password');

      verify(mockDio.post(any, data: anyNamed('data'))).called(1);
    });

    // ~~~~~~~~~~~~~~~~~~~~~~ Password Reset Tests ~~~~~~~~~~~~~~~~~~~~~~
    test('requestPasswordReset completes successfully', () async {
      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
        ),
      );

      await authService.requestPasswordReset('test@example.com');

      verify(mockDio.post(any, data: anyNamed('data'))).called(1);
    });

    test('resetPassword completes successfully', () async {
      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
        ),
      );

      await authService.resetPassword('reset-token', '123456', 'new-password');

      verify(mockDio.post(any, data: anyNamed('data'))).called(1);
    });
  });
}
