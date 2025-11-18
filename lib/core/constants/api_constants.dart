import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// API Constants for the application
/// Automatically detects platform and uses correct localhost address
class ApiConstants {
  ApiConstants._();

  // Base URLs - Platform specific
  // Android Emulator: 10.0.2.2 maps to host machine's localhost
  // iOS/Web/Desktop: localhost works directly
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  static String get wsBaseUrl {
    if (kIsWeb) {
      return 'ws://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'ws://10.0.2.2:8000';
    } else {
      return 'ws://localhost:8000';
    }
  }

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
