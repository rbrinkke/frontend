import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Dio client provider for dependency injection
/// This is the main HTTP client for the application
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        'Content-Type': ApiConstants.contentTypeJson,
        'Accept': ApiConstants.contentTypeJson,
      },
    ),
  );

  // Add interceptors in order:
  // 1. Logging (for debugging)
  // 2. Auth (to add JWT tokens)
  // 3. Error handling (to catch and transform errors)
  dio.interceptors.addAll([
    LoggingInterceptor(logger: Logger()),
    AuthInterceptor(ref: ref),
    ErrorInterceptor(),
  ]);

  return dio;
});

/// Logger provider for the application
final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );
});
