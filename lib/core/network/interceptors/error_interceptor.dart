import 'package:dio/dio.dart';

import '../../errors/api_exception.dart';

/// Error interceptor for global error handling
/// Transforms DioException into custom ApiException with user-friendly messages
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ApiException apiException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        apiException = TimeoutException(
          message: 'Connection timeout. Please check your internet connection and try again.',
        );
        break;

      case DioExceptionType.connectionError:
        apiException = NetworkException(
          message: 'Connection failed. Please check your network and try again.',
        );
        break;

      case DioExceptionType.badResponse:
        apiException = _handleResponseError(err);
        break;

      case DioExceptionType.cancel:
        apiException = ApiException(
          message: 'Request was cancelled.',
          statusCode: null,
        );
        break;

      default:
        apiException = ApiException(
          message: 'An unexpected error occurred. Please try again.',
          statusCode: null,
        );
    }

    // Pass the transformed exception down the chain
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: apiException,
        type: err.type,
        response: err.response,
      ),
    );
  }

  /// Handle HTTP response errors (4xx, 5xx)
  ApiException _handleResponseError(DioException err) {
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;

    // Try to extract error message from response
    String message = 'An error occurred';
    if (data is Map<String, dynamic> && data.containsKey('detail')) {
      message = data['detail'].toString();
    } else if (data is String) {
      message = data;
    }

    switch (statusCode) {
      case 400:
        return ApiException(
          message: message.isNotEmpty ? message : 'Bad request. Please check your input.',
          statusCode: statusCode,
          data: data,
        );

      case 401:
        return UnauthorizedException(
          message: message.isNotEmpty ? message : 'Unauthorized. Please login again.',
        );

      case 403:
        return ApiException(
          message: message.isNotEmpty ? message : 'Access forbidden.',
          statusCode: statusCode,
          data: data,
        );

      case 404:
        return ApiException(
          message: message.isNotEmpty ? message : 'Resource not found.',
          statusCode: statusCode,
          data: data,
        );

      case 422:
        return ApiException(
          message: message.isNotEmpty ? message : 'Validation error. Please check your input.',
          statusCode: statusCode,
          data: data,
        );

      case 500:
      case 502:
      case 503:
        return ServerException(
          message: 'Server error. Please try again later.',
          statusCode: statusCode,
        );

      default:
        return ApiException(
          message: message.isNotEmpty ? message : 'An error occurred (Status: $statusCode)',
          statusCode: statusCode,
          data: data,
        );
    }
  }
}
