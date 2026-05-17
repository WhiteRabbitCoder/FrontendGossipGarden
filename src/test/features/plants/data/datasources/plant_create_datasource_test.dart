import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gossip_garden/features/plants/data/datasources/plant_create_datasource.dart';

http.Response _jsonResponse(String body, [int status = 200]) =>
    http.Response(body, status, headers: {'content-type': 'application/json'});

PlantCreateDatasource _buildDatasource(MockClient client) =>
    PlantCreateDatasource(authToken: 'test_jwt', httpClient: client);

void main() {
  group('PlantCreateDatasource.createPlant', () {
    test('crea planta y devuelve entidad correctamente', () async {
      final responseBody = jsonEncode({
        'plant_id': 'new-plant-uuid',
        'user_id': 'user-uuid',
        'species_id': 'species-uuid',
        'nickname': 'Mi Cactus',
        'health_status': 'healthy',
        'health_score': 100.0,
        'photo_storage_path': 'path/to/photo.jpeg',
        'created_at': '2024-05-11T12:00:00Z',
        'last_health_check': null,
      });
      final client = MockClient((_) async => _jsonResponse(responseBody));
      final datasource = _buildDatasource(client);

      final plant = await datasource.createPlant(
        speciesId: 'species-uuid',
        nickname: 'Mi Cactus',
        photoStoragePath: 'path/to/photo.jpeg',
      );

      expect(plant.id, 'new-plant-uuid');
      expect(plant.name, 'Mi Cactus');
      expect(plant.image, 'path/to/photo.jpeg');
      expect(plant.health, 100.0);
    });

    test('envía el body correcto al endpoint', () async {
      Map<String, dynamic>? capturedBody;
      final client = MockClient((req) async {
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return _jsonResponse(jsonEncode({
          'plant_id': 'p1', 'nickname': 'Test', 'health_score': 100.0,
        }));
      });
      final datasource = _buildDatasource(client);

      await datasource.createPlant(
        speciesId: 'sp-id',
        nickname: 'Test Plant',
        photoStoragePath: 'photo/path.jpeg',
      );

      expect(capturedBody!['species_id'], 'sp-id');
      expect(capturedBody!['nickname'], 'Test Plant');
      expect(capturedBody!['photo_storage_path'], 'photo/path.jpeg');
    });

    test('no incluye photo_storage_path cuando es null', () async {
      Map<String, dynamic>? capturedBody;
      final client = MockClient((req) async {
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return _jsonResponse(jsonEncode({
          'plant_id': 'p1', 'nickname': 'Test', 'health_score': 100.0,
        }));
      });
      final datasource = _buildDatasource(client);

      await datasource.createPlant(speciesId: 'sp-id', nickname: 'Test');

      expect(capturedBody!.containsKey('photo_storage_path'), isFalse);
    });

    test('incluye bearer token en el header', () async {
      String? capturedAuth;
      final client = MockClient((req) async {
        capturedAuth = req.headers['Authorization'];
        return _jsonResponse(jsonEncode({
          'plant_id': 'p1', 'nickname': 'T', 'health_score': 100.0,
        }));
      });
      final datasource = _buildDatasource(client);

      await datasource.createPlant(speciesId: 'sp', nickname: 'T');

      expect(capturedAuth, 'Bearer test_jwt');
    });

    test('lanza Exception con 401', () async {
      final client = MockClient(
        (_) async => _jsonResponse('{"detail": "unauthorized"}', 401),
      );
      final datasource = _buildDatasource(client);

      expect(
        datasource.createPlant(speciesId: 'sp', nickname: 'T'),
        throwsException,
      );
    });

    test('lanza Exception con 422 (validación)', () async {
      final client = MockClient(
        (_) async =>
            _jsonResponse('{"detail": "validation error"}', 422),
      );
      final datasource = _buildDatasource(client);

      expect(
        datasource.createPlant(speciesId: 'sp', nickname: 'T'),
        throwsException,
      );
    });

    test('usa "Mi planta" como fallback para nickname vacío en respuesta', () async {
      final client = MockClient((_) async => _jsonResponse(jsonEncode({
            'plant_id': 'p1',
            // nickname ausente en respuesta
            'health_score': 100.0,
          })));
      final datasource = _buildDatasource(client);
      final plant = await datasource.createPlant(speciesId: 'sp', nickname: 'T');

      expect(plant.name, 'Mi planta');
    });
  });
}
