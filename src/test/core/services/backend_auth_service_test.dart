import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gossip_garden/core/services/backend_auth_service.dart';

http.Response _jsonResponse(String body, [int status = 200]) =>
    http.Response(body, status, headers: {'content-type': 'application/json'});

BackendAuthService _buildService(MockClient client) =>
    BackendAuthService(httpClient: client);

void main() {
  group('BackendAuthService.login', () {
    test('devuelve JWT cuando las credenciales son válidas', () async {
      final client = MockClient((_) async => _jsonResponse(jsonEncode({
            'access_token': 'eyJtest.valid.jwt',
            'token_type': 'Bearer',
          })));
      final service = _buildService(client);

      final token = await service.login('user@example.com', 'password123');

      expect(token, 'eyJtest.valid.jwt');
    });

    test('lanza BackendAuthException con 401', () async {
      final client = MockClient((_) async =>
          _jsonResponse('{"detail": "Credenciales incorrectas"}', 401));
      final service = _buildService(client);

      expect(
        service.login('bad@example.com', 'wrong'),
        throwsA(isA<BackendAuthException>()),
      );
    });

    test('usa detalle del JSON en el mensaje de error', () async {
      final client = MockClient((_) async =>
          _jsonResponse('{"detail": "Email no registrado"}', 401));
      final service = _buildService(client);

      await expectLater(
        service.login('notfound@example.com', 'pass'),
        throwsA(
          isA<BackendAuthException>().having(
            (e) => e.message,
            'message',
            contains('Email no registrado'),
          ),
        ),
      );
    });

    test('lanza BackendAuthException cuando access_token es null', () async {
      final client = MockClient(
        (_) async => _jsonResponse('{"token_type": "Bearer"}'),
      );
      final service = _buildService(client);

      expect(
        service.login('user@example.com', 'pass'),
        throwsA(isA<BackendAuthException>()),
      );
    });

    test('envía email y password en el body', () async {
      Map<String, dynamic>? capturedBody;
      final client = MockClient((req) async {
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return _jsonResponse(
            jsonEncode({'access_token': 'tok', 'token_type': 'Bearer'}));
      });
      final service = _buildService(client);

      await service.login('user@example.com', 'mypassword');

      expect(capturedBody!['email'], 'user@example.com');
      expect(capturedBody!['password'], 'mypassword');
    });
  });

  group('BackendAuthService.register', () {
    test('no lanza excepción con 200', () async {
      final client = MockClient((_) async => _jsonResponse(jsonEncode({
            'status': 'success',
            'message': 'Usuario registrado.',
            'user_id': 'new-uuid',
          })));
      final service = _buildService(client);

      await expectLater(
        service.register(
          email: 'new@example.com',
          password: 'password123',
          username: 'NewUser',
        ),
        completes,
      );
    });

    test('lanza BackendAuthException con 400 (usuario ya existe)', () async {
      final client = MockClient((_) async =>
          _jsonResponse('{"detail": "Email ya registrado"}', 400));
      final service = _buildService(client);

      expect(
        service.register(
          email: 'existing@example.com',
          password: 'pass',
          username: 'User',
        ),
        throwsA(isA<BackendAuthException>()),
      );
    });

    test('envía email, password y username en el body', () async {
      Map<String, dynamic>? capturedBody;
      final client = MockClient((req) async {
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return _jsonResponse(
            jsonEncode({'status': 'success', 'user_id': 'uid'}));
      });
      final service = _buildService(client);

      await service.register(
        email: 'test@example.com',
        password: 'pass',
        username: 'TestUser',
      );

      expect(capturedBody!['email'], 'test@example.com');
      expect(capturedBody!['username'], 'TestUser');
    });
  });

  group('BackendAuthService.signInWithGoogleIdToken', () {
    test('devuelve JWT de Supabase con 200', () async {
      final client = MockClient((_) async => _jsonResponse(jsonEncode({
            'access_token': 'supabase.jwt.from.google',
            'token_type': 'Bearer',
          })));
      final service = _buildService(client);

      final token = await service.signInWithGoogleIdToken('google-id-token');

      expect(token, 'supabase.jwt.from.google');
    });

    test('envía el idToken de Google al endpoint de Supabase', () async {
      Map<String, dynamic>? capturedBody;
      String? capturedUrl;
      final client = MockClient((req) async {
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        capturedUrl = req.url.toString();
        return _jsonResponse(
            jsonEncode({'access_token': 'tok', 'token_type': 'Bearer'}));
      });
      final service = _buildService(client);

      await service.signInWithGoogleIdToken('my-google-id-token');

      expect(capturedUrl, contains('supabase.co'));
      expect(capturedUrl, contains('grant_type=id_token'));
      expect(capturedBody!['id_token'], 'my-google-id-token');
      expect(capturedBody!['provider'], 'google');
    });

    test('lanza BackendAuthException con respuesta errónea de Supabase', () async {
      final client = MockClient(
        (_) async => _jsonResponse('{"error": "invalid_token"}', 400),
      );
      final service = _buildService(client);

      expect(
        service.signInWithGoogleIdToken('bad-token'),
        throwsA(isA<BackendAuthException>()),
      );
    });
  });

  group('BackendAuthException', () {
    test('toString devuelve el mensaje', () {
      final ex = BackendAuthException('Error de autenticación');
      expect(ex.toString(), 'Error de autenticación');
    });
  });
}
