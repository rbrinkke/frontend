import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/api_constants.dart';
import '../secure_storage_service.dart';

/// Auth interceptor for automatic JWT token injection and refreshing
/// This is the KEY to professional-grade authentication (per best practices doc)
class AuthInterceptor extends Interceptor {
  final Ref ref;
  final Dio _dio = Dio(); // Separate dio instance to avoid circular dependencies
  bool _isRefreshing = false;

  AuthInterceptor({required this.ref});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for login and refresh endpoints
    if (options.path == ApiConstants.loginEndpoint ||
        options.path == ApiConstants.refreshTokenEndpoint) {
      return handler.next(options);
    }

    // Get access token from secure storage
    final storageService = ref.read(secureStorageServiceProvider);
    final accessToken = await storageService.getAccessToken();

    // Add Authorization header if token exists
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized - Token expired or invalid
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        // Attempt to refresh the token
        final newAccessToken = await _refreshToken();

        if (newAccessToken != null) {
          // Retry the failed request with new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          // Retry the request
          final response = await _dio.fetch(options);
          _isRefreshing = false;
          return handler.resolve(response);
        }
      } catch (e) {
        _isRefreshing = false;
        // Refresh failed - clear tokens and let error propagate
        final storageService = ref.read(secureStorageServiceProvider);
        await storageService.clearTokens();
        // TODO: Navigate to login screen
      }

      _isRefreshing = false;
    }

    handler.next(err);
  }

  /// Refresh the access token using the refresh token
  /// Returns the new access token or null if refresh failed
  Future<String?> _refreshToken() async {
    try {
      final storageService = ref.read(secureStorageServiceProvider);
      final refreshToken = await storageService.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      // Call refresh token endpoint
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.refreshTokenEndpoint}',
        data: {
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access_token'] as String;
        final newRefreshToken = response.data['refresh_token'] as String?;

        // Save new tokens
        await storageService.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await storageService.saveRefreshToken(newRefreshToken);
        }

        return newAccessToken;
      }
    } catch (e) {
      // Refresh failed
      return null;
    }

    return null;
  }
}
