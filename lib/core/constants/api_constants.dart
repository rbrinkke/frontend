/// API Constants for the application
/// Update these values based on your environment
class ApiConstants {
  ApiConstants._();

  // Base URLs
  static const String baseUrl = 'http://localhost:8000';
  static const String wsBaseUrl = 'ws://localhost:8000';

  // API Endpoints
  static const String loginEndpoint = '/token';
  static const String refreshTokenEndpoint = '/token/refresh';
  static const String usersMeEndpoint = '/users/me';
  static const String geminiChatEndpoint = '/api/gemini/chat';

  // WebSocket Endpoints
  static const String chatWebSocketEndpoint = '/ws/chat';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormUrlEncoded = 'application/x-www-form-urlencoded';
}
