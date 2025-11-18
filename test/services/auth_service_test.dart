import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fastapi_gemini_app/core/network/secure_storage_service.dart';
import 'package:flutter_fastapi_gemini_app/models/auth_models.dart';
import 'package:flutter_fastapi_gemini_app/services/auth_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([Dio, SecureStorageService, AuthService])
void main() {
  late AuthService authService;
  late MockDio mockDio;
  late MockSecureStorageService mockSecureStorageService;

  setUp(() {
    mockDio = MockDio();
    mockSecureStorageService = MockSecureStorageService();
    authService = AuthService(
      dio: mockDio,
      storageService: mockSecureStorageService,
    );
  });

  group('AuthService', () {
    final loginCredentials = LoginCredentials(
      username: 'testuser',
      password: 'testpassword',
    );

    final tokenResponse = TokenResponse(
      accessToken: 'test_access_token',
      refreshToken: 'test_refresh_token',
      tokenType: 'bearer',
    );

    test('login success', () async {
      // Arrange
      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tokenResponse.toJson(),
          statusCode: 200,
        ),
      );

      // Act
      final result = await authService.login(loginCredentials);

      // Assert
      expect(result, isA<TokenResponse>());
      expect(result.accessToken, tokenResponse.accessToken);
      verify(mockSecureStorageService.saveAccessToken(tokenResponse.accessToken))
          .called(1);
      verify(
              mockSecureStorageService.saveRefreshToken(tokenResponse.refreshToken!),)
          .called(1);
    });

    test('login failure', () async {
      // Arrange
      when(mockDio.post(any, data: anyNamed('data')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      // Act & Assert
      expect(
        () => authService.login(loginCredentials),
        throwsA(isA<DioException>()),
      );
    });

    test('getCurrentUser success', () async {
      // Arrange
      final user = User(id: '1', email: 'test@test.com', name: 'Test User');
      when(mockDio.get(any)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: user.toJson(),
          statusCode: 200,
        ),
      );

      // Act
      final result = await authService.getCurrentUser();

      // Assert
      expect(result, isA<User>());
      expect(result.id, user.id);
    });

    test('logout', () async {
      // Act
      await authService.logout();

      // Assert
      verify(mockSecureStorageService.clearTokens()).called(1);
    });

    test('isLoggedIn', () async {
      // Arrange
      when(mockSecureStorageService.isLoggedIn()).thenAnswer((_) async => true);

      // Act
      final result = await authService.isLoggedIn();

      // Assert
      expect(result, isTrue);
    });
  });
}
