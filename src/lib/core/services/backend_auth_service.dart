import 'package:dio/dio.dart';
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
      await _tokenStorage.saveToken(tokenResponse.accessToken);
      return tokenResponse;
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Error desconocido';
      throw Exception(message);
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
      throw Exception(message);
    }
  }

  Future<GoogleUrlResponse?> getGoogleAuthUrl() async {
    try {
      final response = await _apiClient.dio.get('/auth/google-url');
      return GoogleUrlResponse.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Error desconocido';
      throw Exception(message);
    }
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
  }
  
  Future<String?> getStoredToken() async {
    return await _tokenStorage.getToken();
  }
}
