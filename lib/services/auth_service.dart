import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../core/network/secure_storage_service.dart';
import '../models/auth_models.dart';

/// Auth service for handling authentication
class AuthService {
  final Dio _dio;
  final SecureStorageService _storageService;

  AuthService({
    required Dio dio,
    required SecureStorageService storageService,
  })  : _dio = dio,
        _storageService = storageService;

  /// Login with username and password
  /// CRITICAL: Uses FormData instead of JSON body (per best practices doc)
  /// This is required by FastAPI's OAuth2PasswordRequestForm
  Future<TokenResponse> login(LoginCredentials credentials) async {
    // IMPORTANT: OAuth2 requires application/x-www-form-urlencoded
    // NOT JSON! This is a common pitfall mentioned in the best practices doc.
    final formData = FormData.fromMap({
      'username': credentials.username,
      'password': credentials.password,
    });

    final response = await _dio.post(
      ApiConstants.loginEndpoint,
      data: formData,
    );

    final tokenResponse = TokenResponse.fromJson(response.data);

    // Save tokens to secure storage
    await _storageService.saveAccessToken(tokenResponse.accessToken);
    if (tokenResponse.refreshToken != null) {
      await _storageService.saveRefreshToken(tokenResponse.refreshToken!);
    }

    return tokenResponse;
  }

  /// Get current user info
  Future<User> getCurrentUser() async {
    final response = await _dio.get(ApiConstants.usersMeEndpoint);
    return User.fromJson(response.data);
  }

  /// Logout - clear all tokens
  Future<void> logout() async {
    await _storageService.clearTokens();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }
}

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.read(dioProvider);
  final storageService = ref.read(secureStorageServiceProvider);

  return AuthService(
    dio: dio,
    storageService: storageService,
  );
});
