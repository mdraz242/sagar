import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_token_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required this.storage,
    this.onSessionExpired,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 25),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 30),
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_skipsAuth(options.path)) {
            final token = await storage.accessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final retried = error.requestOptions.extra['retried'] == true;
          if (status == 401 &&
              !retried &&
              !_skipsAuth(error.requestOptions.path)) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final request = error.requestOptions;
              request.extra['retried'] = true;
              final token = await storage.accessToken();
              request.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await dio.fetch<dynamic>(request);
                handler.resolve(response);
                return;
              } on DioException catch (retryError) {
                handler.next(retryError);
                return;
              }
            }
            // Keep the secure session intact on refresh failure. Render cold
            // starts and mobile network drops can make a valid refresh request
            // fail; explicit logout/delete are the only flows that clear it.
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final SecureTokenStorage storage;
  final Future<void> Function()? onSessionExpired;

  Future<void> warmUp() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await dio.get<dynamic>(
          '/health',
          options: Options(
            receiveTimeout: const Duration(seconds: 30),
            extra: {'warmup': true},
          ),
        );
        return;
      } catch (_) {
        if (attempt == 2) return;
        await Future<void>.delayed(Duration(milliseconds: 800 * (attempt + 1)));
      }
    }
  }

  bool _skipsAuth(String path) {
    return path.contains('/auth/otp/send') ||
        path.contains('/auth/otp/resend') ||
        path.contains('/auth/otp/request') ||
        path.contains('/auth/otp/verify') ||
        path.contains('/auth/login') ||
        path.contains('/auth/lookup') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path == '/health' ||
        path.endsWith('/health');
  }

  Future<bool> _refreshToken() async {
    final refresh = await storage.refreshToken();
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
        options: Options(extra: {'skipRefresh': true}),
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      final accessToken = data?['accessToken'] as String?;
      final refreshToken = data?['refreshToken'] as String?;
      if (accessToken == null || refreshToken == null) return false;
      await storage.save(accessToken, refreshToken);
      return true;
    } on DioException catch (error) {
      if (_isTransient(error)) {
        await warmUp();
      }
      return false;
    }
  }

  bool _isTransient(DioException error) {
    final status = error.response?.statusCode;
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        (status != null && status >= 500);
  }
}

T unwrapData<T>(Response<dynamic> response) {
  final body = response.data;
  if (body is Map<String, dynamic>) {
    if (body['success'] == false) {
      final error = body['error'];
      if (error is Map<String, dynamic>) {
        throw ApiException(error['message']?.toString() ?? 'Request failed');
      }
      throw const ApiException('Request failed');
    }
    return body['data'] as T;
  }
  throw const ApiException('Invalid API response');
}

String apiErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final apiError = data['error'];
      if (apiError is Map<String, dynamic>) {
        return apiError['message']?.toString() ?? 'Network request failed';
      }
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Network unavailable. Please check your connection.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The server took too long to respond.';
    }
  }
  return 'Something went wrong. Please try again.';
}
