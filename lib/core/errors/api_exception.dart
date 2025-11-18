/// Custom API exceptions for the application
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException({required super.message})
      : super(statusCode: null);
}

class TimeoutException extends ApiException {
  TimeoutException({required super.message})
      : super(statusCode: 408);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({required super.message})
      : super(statusCode: 401);
}

class ServerException extends ApiException {
  ServerException({required super.message, super.statusCode});
}
