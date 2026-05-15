import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:gossip_garden/core/config/app_config.dart';
import '../models/identification.dart';

class IdentificationApiDatasource {
  IdentificationApiDatasource({
    required this.authToken,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String? authToken;
  final http.Client _httpClient;

  Map<String, String> get _authHeaders => {
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  /// Sube una imagen y llama a POST /api/v1/identify.
  /// Devuelve el resultado discriminado por el campo `status`.
  Future<IdentifyResult> identify({
    required File image,
    double? latitude,
    double? longitude,
    String outputLanguage = 'es',
  }) async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/v1/identify');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeaders)
      ..fields['output_language'] = outputLanguage
      ..files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        contentType: MediaType('image', 'jpeg'),
      ));

    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();

    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Por favor vuelve a iniciar sesión.');
    }
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode} al identificar: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseResult(json);
  }

  /// Completa el pipeline para un candidato elegido por el usuario.
  /// Llama a POST /api/v1/species/from-candidate.
  Future<IdentifyCompleted> fromCandidate({
    required SpeciesCandidate candidate,
    String outputLanguage = 'es',
  }) async {
    final uri =
        Uri.parse('${AppConfig.backendBaseUrl}/api/v1/species/from-candidate');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        ..._authHeaders,
      },
      body: jsonEncode({
        'candidate': candidate.toJson(),
        'output_language': outputLanguage,
      }),
    );

    if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Por favor vuelve a iniciar sesión.');
    }
    if (response.statusCode != 200) {
      throw Exception(
          'Error ${response.statusCode} al completar candidato: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final result = _parseResult(json);
    if (result is! IdentifyCompleted) {
      throw Exception('Respuesta inesperada de from-candidate: ${json['status']}');
    }
    return result;
  }

  IdentifyResult _parseResult(Map<String, dynamic> json) {
    final status = json['status'] as String?;
    switch (status) {
      case 'needs_more_photos':
        return NeedsMorePhotos(
          reason: json['reason'] as String? ?? 'Confianza insuficiente',
          topProbability: (json['top_probability'] as num?)?.toDouble() ?? 0.0,
        );

      case 'needs_user_selection':
        final candidates = (json['candidates'] as List? ?? [])
            .map((e) => SpeciesCandidate.fromJson(e as Map<String, dynamic>))
            .toList();
        return NeedsUserSelection(candidates: candidates);

      case 'completed':
        final profile =
            CareProfile.fromJson(json['profile'] as Map<String, dynamic>);
        return IdentifyCompleted(
          profile: profile,
          photoStoragePath: json['photo_storage_path'] as String?,
        );

      default:
        throw Exception('Estado de identificación desconocido: $status');
    }
  }
}
