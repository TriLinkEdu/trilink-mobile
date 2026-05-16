import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';
import '../services/sync_queue_service.dart';
import '../services/telemetry_service.dart';
import 'api_exceptions.dart';

class ApiClient {
  static ApiClient? _instance;
  
  factory ApiClient({
    StorageService? storageService,
    SyncQueueService? syncQueue,
    TelemetryService? telemetry,
  }) {
    _instance ??= ApiClient._internal(storageService, syncQueue, telemetry);
    return _instance!;
  }

  late final Dio dio;
  final StorageService _storage;
  final SyncQueueService? _syncQueue;
  final TelemetryService? _telemetry;
  bool _isRefreshing = false;

  ApiClient._internal(StorageService? storageService, this._syncQueue, this._telemetry) 
    : _storage = storageService ?? StorageService() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        // Keep login and data calls resilient on slower networks.
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 45),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest, 
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final startTime = response.requestOptions.extra['startTime'] as int?;
    if (startTime != null) {
      final duration = DateTime.now().millisecondsSinceEpoch - startTime;
      _telemetry?.recordNetworkHit(response.requestOptions.path, duration);
    }
    handler.next(response);
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
          final res = await Dio(
            BaseOptions(baseUrl: ApiConstants.baseUrl),
          ).post(ApiConstants.refresh, data: {'refreshToken': rt});
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
          opts.headers['Authorization'] = 'Bearer ${data['accessToken']}';
          final retry = await dio.fetch(opts);
          return handler.resolve(retry);
        }
      } catch (_) {
        _isRefreshing = false;
        await _storage.clearAll();
      }
    }

    // Measure latency even on errors
    final startTime = err.requestOptions.extra['startTime'] as int?;
    if (startTime != null) {
      final duration = DateTime.now().millisecondsSinceEpoch - startTime;
      _telemetry?.recordNetworkHit(err.requestOptions.path, duration);
    }

    // Queue failed mutations (Optimistic UI)
    if (_isNetworkError(err) && _isMutation(err.requestOptions.method)) {
      await _syncQueue?.enqueue(
        path: err.requestOptions.path,
        method: err.requestOptions.method,
        data: err.requestOptions.data,
      );
      
      // Return a mock success response so UI proceeds optimistically
      return handler.resolve(
        Response(
          requestOptions: err.requestOptions,
          statusCode: 202, // Accepted for background processing
          data: {'status': 'queued_offline'},
        ),
      );
    }

    handler.next(err);
  }

  bool _isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.connectionError ||
           err.type == DioExceptionType.unknown;
  }

  bool _isMutation(String method) {
    final m = method.toUpperCase();
    return m == 'POST' || m == 'PUT' || m == 'PATCH' || m == 'DELETE';
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await dio.get(path, queryParameters: queryParameters);
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
      final res = await dio.get(path, queryParameters: queryParameters);
      if (res.data is List) return res.data as List<dynamic>;
      // Handle wrapped responses like {"data": [...], "meta": {...}}
      if (res.data is Map<String, dynamic>) {
        final payload = res.data['data'];
        if (payload is List) return payload;
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final res = await dio.post(path, data: data);
      return _extractData(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> patch(String path, {dynamic data}) async {
    try {
      final res = await dio.patch(path, data: data);
      return _extractData(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    try {
      final res = await dio.put(path, data: data);
      return _extractData(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String path, {dynamic data}) async {
    try {
      final res = await dio.delete(path, data: data);
      return _extractData(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?additionalData,
      });
      
      final res = await dio.post(
        path,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return _extractData(res);
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
    if (e.type == DioExceptionType.connectionError) {
      return NetworkException();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'Connection is slow and request timed out. Please try again.',
      );
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
