import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'package:gossip_garden/core/config/app_config.dart';

import '../models/realtime_sensor_snapshot.dart';

class SensorStreamDatasource {
  SensorStreamDatasource({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  
  // Cambia esto a 'false' para volver a conectar con el servidor real
  static const bool useMockData = true;

  Stream<RealtimeSensorSnapshot> watchPlantSensor(int plantId) async* {
    if (useMockData) {
      final random = math.Random();
      while (true) {
        await Future.delayed(const Duration(seconds: 2));
        yield RealtimeSensorSnapshot.fromJson({
          "humidity": 65.0 + random.nextDouble() * 2,
          "temperature": 22.0 + random.nextDouble(),
          "light": 300.0 + random.nextDouble() * 10,
          "soil_moisture": 55.0 + random.nextDouble() * 5,
          "timestamp": DateTime.now().toUtc().toIso8601String()
        });
      }
    }

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
