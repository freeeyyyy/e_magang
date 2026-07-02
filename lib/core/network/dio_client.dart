import 'package:dio/dio.dart';
import '../services/secure_storage_service.dart';
import '../constants/api_endpoints.dart';

class DioClient {
  final Dio _dio;
  final SecureStorageService _secureStorage;
  void Function()? onUnauthorized;

  DioClient(this._secureStorage, {this.onUnauthorized}) : _dio = Dio() {
    _dio.options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Retrieve token from secure storage and append it as Bearer token
          final token = await _secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // If response is 401 Unauthorized, call the unauthorized callback
          if (e.response?.statusCode == 401) {
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // General GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // General POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Handle errors
  ApiException _handleError(DioException e) {
    String message = 'Terjadi kesalahan koneksi';
    int? statusCode = e.response?.statusCode;

    if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Koneksi ke server habis waktu (Timeout)';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Server lambat merespon (Receive Timeout)';
    } else if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        message = data['message'];
      } else {
        message = 'Kesalahan Server (${e.response?.statusCode})';
      }
    }

    return ApiException(message, statusCode: statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
