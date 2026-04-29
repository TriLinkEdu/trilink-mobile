import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';
import 'api_exceptions.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final StorageService _storage = StorageService();
  bool _isRefreshing = false;

  ApiClient._internal() {
    print('🔧 API Client initialized with baseUrl: ${ApiConstants.baseUrl}');
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final rt = await _storage.refreshToken;
        if (rt != null) {
          final res = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
              .post(ApiConstants.refresh, data: {'refreshToken': rt});
          final data = res.data as Map<String, dynamic>;
          await _storage.saveTokens(
            accessToken: data['accessToken'] as String,
            refreshToken: data['refreshToken'] as String,
          );
          if (data['user'] != null) {
            await _storage.saveUser(data['user'] as Map<String, dynamic>);
          }
          _isRefreshing = false;
          final opts = err.requestOptions;
          opts.headers['Authorization'] =
              'Bearer ${data['accessToken']}';
          final retry = await _dio.fetch(opts);
          return handler.resolve(retry);
        }
      } catch (_) {
        _isRefreshing = false;
        await _storage.clearAll();
      }
    }
    handler.next(err);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: queryParameters);
      return _extractData(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: queryParameters);
      if (res.data is List) return res.data as List<dynamic>;
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
  }) async {
    try {
      final res = await _dio.post(path, data: data);
      return _extractData(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic data,
  }) async {
    try {
      final res = await _dio.patch(path, data: data);
      return _extractData(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
  }) async {
    try {
      final res = await _dio.put(path, data: data);
      return _extractData(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Map<String, dynamic> _extractData(Response res) {
    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    return {'data': res.data};
  }

  ApiException _handleDioError(DioException e) {
    print('🚨 DioException: ${e.type} - ${e.message}');
    print('🚨 Request URL: ${e.requestOptions.uri}');
    
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException(message: 'Cannot connect to ${e.requestOptions.uri.host}:${e.requestOptions.uri.port}');
    }
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Something went wrong';
    if (data is Map<String, dynamic>) {
      final raw = data['message'];
      if (raw is String) {
        message = raw;
      } else if (raw is List) {
        message = raw.join(', ');
      }
    }
    if (statusCode == 401) return UnauthorizedException(message: message);
    return ApiException(message: message, statusCode: statusCode);
  }
}
