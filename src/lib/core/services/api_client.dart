import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'token_storage.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  ApiClient({TokenStorage? storage}) 
      : tokenStorage = storage ?? TokenStorage(),
        dio = Dio(BaseOptions(
          baseUrl: AppConfig.backendBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: Headers.jsonContentType,
        )) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
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
        // Aquí podríamos manejar lógica para refrescar el token si hubiera refresh token,
        // o emitir un evento global para cerrar sesión si es 401.
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
