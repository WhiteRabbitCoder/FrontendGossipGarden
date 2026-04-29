import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:gossip_garden/core/config/app_config.dart';

import '../models/realtime_sensor_snapshot.dart';

class SensorStreamDatasource {
  SensorStreamDatasource({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Stream<RealtimeSensorSnapshot> watchPlantSensor(int plantId) async* {
    final uri =
        Uri.parse('${AppConfig.backendBaseUrl}/sensor_data/$plantId/stream');
    final request = http.Request('GET', uri)
      ..headers['Accept'] = 'text/event-stream';

    final streamed = await _httpClient.send(request);

    await for (final line in streamed.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!line.startsWith('data: ')) {
        continue;
      }

      final payload = line.substring(6).trim();
      if (payload.isEmpty) {
        continue;
      }

      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        yield RealtimeSensorSnapshot.fromJson(decoded);
      } else if (decoded is Map) {
        yield RealtimeSensorSnapshot.fromJson(
            Map<String, dynamic>.from(decoded));
      }
    }
  }
}
