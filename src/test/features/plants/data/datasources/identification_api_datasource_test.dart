import 'dart:convert' show jsonDecode, latin1;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gossip_garden/features/plants/data/datasources/identification_api_datasource.dart';
import 'package:gossip_garden/features/plants/data/models/identification.dart';

import '../../../../helpers/fixture_loader.dart';

http.Response _jsonResponse(String body, [int status = 200]) =>
    http.Response(body, status, headers: {'content-type': 'application/json'});

IdentificationApiDatasource _buildDatasource(MockClient client) =>
    IdentificationApiDatasource(authToken: 'test_jwt', httpClient: client);

void main() {
  late File tempImage;

  setUpAll(() async {
    // Crea un archivo temporal de imagen (1x1 JPEG mínimo)
    final dir = Directory.systemTemp;
    tempImage = File('${dir.path}/test_plant.jpg');
    await tempImage.writeAsBytes([
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, // JPEG header
      0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01,
      0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9, // JPEG footer
    ]);
  });

  tearDownAll(() async {
    if (await tempImage.exists()) await tempImage.delete();
  });

  group('identify — estado needs_more_photos', () {
    test('parsea respuesta needs_more_photos correctamente', () async {
      final client = MockClient(
        (_) async => _jsonResponse(loadFixture('identify_needs_photos.json')),
      );
      final datasource = _buildDatasource(client);

      final result = await datasource.identify(image: tempImage);

      expect(result, isA<NeedsMorePhotos>());
      final r = result as NeedsMorePhotos;
      expect(r.topProbability, 0.18);
      expect(r.reason, contains('baja'));
    });
  });

  group('identify — estado needs_user_selection', () {
    test('parsea respuesta con candidatos', () async {
      final client = MockClient(
        (_) async =>
            _jsonResponse(loadFixture('identify_needs_selection.json')),
      );
      final datasource = _buildDatasource(client);

      final result = await datasource.identify(image: tempImage);

      expect(result, isA<NeedsUserSelection>());
      final r = result as NeedsUserSelection;
      expect(r.candidates, hasLength(3));
      expect(r.candidates.first.scientificName, 'Monstera deliciosa');
      expect(r.candidates.first.probability, 0.62);
    });
  });

  group('identify — estado completed', () {
    test('parsea respuesta completed con perfil completo', () async {
      final client = MockClient(
        (_) async => _jsonResponse(loadFixture('identify_completed.json')),
      );
      final datasource = _buildDatasource(client);

      final result = await datasource.identify(image: tempImage);

      expect(result, isA<IdentifyCompleted>());
      final r = result as IdentifyCompleted;
      expect(r.profile.scientificName, 'Monstera deliciosa');
      expect(r.photoStoragePath, contains('Monstera_deliciosa'));
      expect(r.profile.careRanges.minTempC, 18.0);
      expect(r.profile.careWeights, isNotNull);
    });
  });

  group('identify — manejo de errores HTTP', () {
    test('lanza Exception con 401', () async {
      final client = MockClient(
        (_) async => _jsonResponse('{"detail": "Unauthorized"}', 401),
      );
      final datasource = _buildDatasource(client);

      expect(datasource.identify(image: tempImage), throwsException);
    });

    test('lanza Exception con 500', () async {
      final client = MockClient(
        (_) async => _jsonResponse('{"error": "server error"}', 500),
      );
      final datasource = _buildDatasource(client);

      expect(datasource.identify(image: tempImage), throwsException);
    });

    test('lanza Exception para status desconocido', () async {
      final client = MockClient(
        (_) async => _jsonResponse('{"status": "unknown_state"}'),
      );
      final datasource = _buildDatasource(client);

      expect(datasource.identify(image: tempImage), throwsException);
    });
  });

  group('identify — opciones de idioma y ubicación', () {
    test('incluye output_language en el request', () async {
      // MockClient convierte MultipartRequest → Request con bodyBytes ya populados.
      // La imagen JPEG contiene bytes no-UTF8; usamos latin1 que acepta cualquier byte.
      String? capturedBody;
      final client = MockClient((req) async {
        capturedBody = latin1.decode(req.bodyBytes);
        return _jsonResponse(loadFixture('identify_completed.json'));
      });
      final datasource = _buildDatasource(client);

      await datasource.identify(image: tempImage, outputLanguage: 'en');

      expect(capturedBody, contains('output_language'));
      expect(capturedBody, contains('en'));
    });

    test('incluye latitud y longitud cuando se proveen', () async {
      String? capturedBody;
      final client = MockClient((req) async {
        capturedBody = latin1.decode(req.bodyBytes);
        return _jsonResponse(loadFixture('identify_completed.json'));
      });
      final datasource = _buildDatasource(client);

      await datasource.identify(
        image: tempImage,
        latitude: 4.6097,
        longitude: -74.0817,
      );

      expect(capturedBody, contains('4.6097'));
      expect(capturedBody, contains('-74.0817'));
    });
  });

  group('fromCandidate', () {
    late SpeciesCandidate candidate;

    setUp(() {
      candidate = const SpeciesCandidate(
        scientificName: 'Monstera deliciosa',
        commonNames: ['Costilla de Adán'],
        probability: 0.62,
        gbifId: 2684241,
        family: 'Araceae',
        genus: 'Monstera',
      );
    });

    test('devuelve IdentifyCompleted correctamente', () async {
      final responseBody = loadFixture('identify_completed.json');
      final client = MockClient((_) async => _jsonResponse(responseBody));
      final datasource = _buildDatasource(client);

      final result = await datasource.fromCandidate(candidate: candidate);

      expect(result, isA<IdentifyCompleted>());
      expect(result.profile.scientificName, 'Monstera deliciosa');
    });

    test('envía el candidate serializado en el body', () async {
      String? capturedBody;
      final client = MockClient((req) async {
        capturedBody = req.body;
        return _jsonResponse(loadFixture('identify_completed.json'));
      });
      final datasource = _buildDatasource(client);

      await datasource.fromCandidate(candidate: candidate);

      final decoded = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(decoded['candidate']['scientific_name'], 'Monstera deliciosa');
      expect(decoded['output_language'], 'es');
    });

    test('lanza Exception si la respuesta no es completed', () async {
      final client = MockClient(
        (_) async =>
            _jsonResponse(loadFixture('identify_needs_photos.json')),
      );
      final datasource = _buildDatasource(client);

      expect(
        datasource.fromCandidate(candidate: candidate),
        throwsException,
      );
    });

    test('lanza Exception con 401', () async {
      final client = MockClient(
        (_) async => _jsonResponse('{"detail": "unauthorized"}', 401),
      );
      final datasource = _buildDatasource(client);

      expect(
        datasource.fromCandidate(candidate: candidate),
        throwsException,
      );
    });
  });
}
