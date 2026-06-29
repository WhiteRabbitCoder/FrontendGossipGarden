import 'package:dio/dio.dart';
import 'package:gossip_garden/core/config/app_config.dart';
import 'package:gossip_garden/core/services/api_client.dart';
import 'package:gossip_garden/core/services/token_storage.dart';
import 'package:gossip_garden/features/auth/data/auth_dto.dart';

class BackendAuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  BackendAuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<TokenResponse?> login(UserLogin loginData) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: loginData.toJson(),
      );
      
      final tokenResponse = TokenResponse.fromJson(response.data);
      await _tokenStorage.saveToken(
        tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );
      return tokenResponse;
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Error desconocido';
      throw AuthException(message);
    }
  }

  Future<String?> register(UserRegister registerData) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: registerData.toJson(),
      );
      
      return response.data['user_id'] as String?;
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Error desconocido';
      throw AuthException(message);
    }
  }

  Future<TokenResponse> refreshToken(String refreshToken) async {
    try {
      final response = await Dio().post(
        '${AppConfig.backendBaseUrl}/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      final tokenResponse = TokenResponse.fromJson(response.data);
      await _tokenStorage.saveToken(
        tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );
      return tokenResponse;
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Error renovando sesión';
      throw AuthException(message);
    }
  }

  Future<GoogleUrlResponse?> getGoogleAuthUrl() async {
    try {
      final response = await _apiClient.dio.get('/auth/google-url');
      return GoogleUrlResponse.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Error desconocido';
      throw AuthException(message);
    }
  }

  Future<String> signInWithGoogleIdToken(String idToken) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        '${AppConfig.supabaseUrl}/auth/v1/token?grant_type=id_token',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'apikey': AppConfig.supabaseAnonKey,
          },
        ),
        data: {
          'provider': 'google',
          'id_token': idToken,
          'client_id': AppConfig.googleClientId,
        },
      );

      final token = response.data['access_token'] as String?;
      final refreshToken = response.data['refresh_token'] as String?;
      if (token == null) {
        throw Exception('Respuesta de Supabase inválida');
      }
      await _tokenStorage.saveToken(token, refreshToken: refreshToken);
      return token;
    } on DioException catch (e) {
      final message = e.response?.data?['error_description'] ?? e.response?.data?['msg'] ?? 'Error al autenticar con Google';
      throw AuthException(message);
    }
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
  }
  
  Future<String?> getStoredToken() async {
    return await _tokenStorage.getToken();
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      return response.data;
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Error al obtener perfil';
      throw AuthException(message);
    }
  }

  Future<void> updateUserProfile({String? username, String? preferredLanguage}) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (preferredLanguage != null) data['preferred_language'] = preferredLanguage;
      if (data.isNotEmpty) {
        await _apiClient.dio.patch('/users/me', data: data);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Error al actualizar perfil';
      throw AuthException(message);
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
