import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../core/network/secure_storage_service.dart';
import '../models/auth_models.dart';

/// Auth service for handling the new multi-step authentication flows
class AuthService {
  final Dio _dio;
  final SecureStorageService _storageService;

  AuthService({
    required Dio dio,
    required SecureStorageService storageService,
  })  : _dio = dio,
        _storageService = storageService;

  /// Login Step 1: Send email and password
  /// Returns a sealed LoginResponse which can be TokenResponse,
  /// LoginCodeSentResponse, or OrganizationSelectionResponse
  Future<LoginResponse> loginStep1(String email, String password) async {
    final request = LoginRequest(email: email, password: password);
    final response = await _dio.post(
      ApiConstants.loginEndpoint,
      data: request.toJson(),
    );
    return LoginResponse.fromJson(response.data);
  }

  /// Login Step 2: Send email, password, and the verification code
  Future<LoginResponse> loginStep2(String email, String password, String code, {String? orgId}) async {
    final request = LoginRequest(email: email, password: password, code: code, orgId: orgId);
    final response = await _dio.post(
      ApiConstants.loginEndpoint,
      data: request.toJson(),
    );
    final loginResponse = LoginResponse.fromJson(response.data);

    if (loginResponse is TokenResponse) {
      await _saveTokens(loginResponse);
    }

    return loginResponse;
  }

  /// Register a new user
  Future<void> register(String email, String password) async {
    final request = UserCreate(email: email, password: password);
    await _dio.post(
      ApiConstants.registerEndpoint,
      data: request.toJson(),
    );
  }

  /// Verify email with a verification token and code
  Future<void> verifyEmail(String verificationToken, String code) async {
    final request = VerifyEmailRequest(verificationToken: verificationToken, code: code);
    await _dio.post(
      ApiConstants.verifyCodeEndpoint,
      data: request.toJson(),
    );
  }

  /// Request a password reset email
  Future<void> requestPasswordReset(String email) async {
    final request = RequestPasswordResetRequest(email: email);
    await _dio.post(
      ApiConstants.requestPasswordResetEndpoint,
      data: request.toJson(),
    );
  }

  /// Reset password with a reset token, code, and new password
  Future<void> resetPassword(String resetToken, String code, String newPassword) async {
    final request = ResetPasswordRequest(
      resetToken: resetToken,
      code: code,
      newPassword: newPassword,
    );
    await _dio.post(
      ApiConstants.resetPasswordEndpoint,
      data: request.toJson(),
    );
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

  /// Helper to save tokens
  Future<void> _saveTokens(TokenResponse tokenResponse) async {
    await _storageService.saveAccessToken(tokenResponse.accessToken);
    await _storageService.saveRefreshToken(tokenResponse.refreshToken);
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
