import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Logging interceptor for debugging API calls
/// Logs all requests, responses, and errors
class LoggingInterceptor extends Interceptor {
  final Logger logger;

  LoggingInterceptor({required this.logger});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.i(
      'REQUEST[${options.method}] => PATH: ${options.uri}\n'
      'Headers: ${options.headers}\n'
      'Data: ${options.data}',
    );
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.i(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.uri}\n'
      'Data: ${response.data}',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.uri}\n'
      'Message: ${err.message}\n'
      'Data: ${err.response?.data}',
    );
    super.onError(err, handler);
  }
}
