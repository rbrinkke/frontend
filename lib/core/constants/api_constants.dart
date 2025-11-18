/// API Constants for the application
/// Update these values based on your environment
class ApiConstants {
  ApiConstants._();

  // Base URLs
  // Use 10.0.2.2 for Android Emulator to connect to localhost
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String wsBaseUrl = 'ws://10.0.2.2:8000';

  // API Endpoints
  // Note: /token is for standard OAuth2, /api/auth/login is for the new flow
  static const String oauthTokenEndpoint = '/token';
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String verifyCodeEndpoint = '/api/auth/verify-code';
  static const String requestPasswordResetEndpoint = '/api/auth/request-password-reset';
  static const String resetPasswordEndpoint = '/api/auth/reset-password';

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
