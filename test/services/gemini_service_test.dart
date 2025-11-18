import 'package:dio/dio.dart';
import 'package:flutter_fastapi_gemini_app/services/gemini_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'auth_service_test.mocks.dart'; // Re-using mocks from auth_service_test

@GenerateMocks([WebSocketChannel])
void main() {
  late GeminiService geminiService;
  late MockDio mockDio;
  late MockSecureStorageService mockSecureStorageService;

  setUp(() {
    mockDio = MockDio();
    mockSecureStorageService = MockSecureStorageService();
    geminiService = GeminiService(
      dio: mockDio,
      storageService: mockSecureStorageService,
    );
  });

  group('GeminiService', () {
    test('sendMessage success', () async {
      // Arrange
      const message = 'Hello Gemini';
      final responseData = {'response': 'Hello from Gemini'};
      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: responseData,
          statusCode: 200,
        ),
      );

      // Act
      final result = await geminiService.sendMessage(message);

      // Assert
      expect(result, equals(responseData));
    });

    test('connectToChatWebSocket success', () async {
      // Arrange
      const accessToken = 'test_access_token';
      when(mockSecureStorageService.getAccessToken())
          .thenAnswer((_) async => accessToken);

      // Act
      final result = await geminiService.connectToChatWebSocket();

      // Assert
      expect(result, isA<WebSocketChannel>());
    });
  });
}
