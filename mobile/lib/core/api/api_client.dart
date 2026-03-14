import 'package:dio/dio.dart';
import '../storage/auth_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  static Dio create() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Auth interceptor — adds JWT token to every request
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AuthStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired — try refresh
          final refreshed = await _refreshToken(dio);
          if (refreshed) {
            final token = await AuthStorage.getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          } else {
            await AuthStorage.clear();
          }
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  static Future<bool> _refreshToken(Dio dio) async {
    try {
      final refreshToken = await AuthStorage.getRefreshToken();
      if (refreshToken == null) return false;
      final response = await dio.post('/auth/refresh',
          data: {'refreshToken': refreshToken});
      await AuthStorage.saveTokens(
        accessToken: response.data['accessToken'],
        refreshToken: response.data['refreshToken'],
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
