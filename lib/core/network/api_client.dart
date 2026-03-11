/// Base API client for making HTTP requests.
/// TODO: Implement with dio or http package.
class ApiClient {
  // Singleton
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // TODO: Add base configuration, interceptors, token handling
}
