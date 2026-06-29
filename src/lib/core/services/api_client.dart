import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'token_storage.dart';

class ApiClient {
  static final StreamController<void> _unauthorizedController = StreamController<void>.broadcast();
  static Stream<void> get onUnauthorized => _unauthorizedController.stream;

  final Dio dio;
  final TokenStorage tokenStorage;

  ApiClient({TokenStorage? storage}) 
      : tokenStorage = storage ?? TokenStorage(),
        dio = Dio(BaseOptions(
          baseUrl: AppConfig.backendBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          contentType: Headers.jsonContentType,
        )) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Asegurar que la ruta comience con /api/v1 si no es absoluta o ya lo tiene
        if (!options.path.startsWith('/api/v1') &&
            !options.path.startsWith('http://') &&
            !options.path.startsWith('https://')) {
          final cleanPath = options.path.startsWith('/') ? options.path : '/${options.path}';
          options.path = '/api/v1$cleanPath';
        }

        // Rutas públicas que no requieren token
        final isPublicRoute = options.path.contains('/auth/login') ||
            options.path.contains('/auth/register') ||
            options.path.contains('/sensors/');

        if (!isPublicRoute) {
          final token = await tokenStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          _unauthorizedController.add(null);
        }
        return handler.next(e);
      },
    ));
    
    // Log interceptor en debug mode
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ));
  }
}
