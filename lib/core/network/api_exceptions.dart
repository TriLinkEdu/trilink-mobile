class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException extends ApiException {
  NetworkException({super.message = 'No internet connection'});
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({
    super.message = 'Unauthorized',
    super.statusCode = 401,
  });
}
