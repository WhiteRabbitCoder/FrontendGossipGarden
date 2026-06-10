import '../models/realtime_sensor_snapshot.dart';

/// Umbral mínimo de subida de humedad de suelo (%) para considerar un riego.
const kSoilMoistureWateringDelta = 5.0;

/// Subida combinada suelo + ambiente cuando la del suelo es más leve.
const kSoilMoistureCombinedDelta = 3.0;
const kHumidityCombinedDelta = 2.0;

/// Tiempo mínimo entre dos riegos contados para la misma planta.
const kWateringCooldown = Duration(hours: 3);

class PlantSensorBaseline {
  final double soilMoisture;
  final double humidity;
  final String recordedAt;

  const PlantSensorBaseline({
    required this.soilMoisture,
    required this.humidity,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'soilMoisture': soilMoisture,
        'humidity': humidity,
        'recordedAt': recordedAt,
      };

  factory PlantSensorBaseline.fromJson(Map<String, dynamic> json) {
    return PlantSensorBaseline(
      soilMoisture: (json['soilMoisture'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0,
      recordedAt: json['recordedAt'] as String? ?? '',
    );
  }
}

class WateringDetectionResult {
  final bool detected;
  final double soilDelta;
  final double humidityDelta;

  const WateringDetectionResult({
    required this.detected,
    required this.soilDelta,
    required this.humidityDelta,
  });
}

WateringDetectionResult detectWateringFromSensorVariation({
  required PlantSensorBaseline previous,
  required RealtimeSensorSnapshot current,
}) {
  final soil = current.soilMoisture;
  final humidity = current.humidity;

  if (soil == null) {
    return const WateringDetectionResult(
      detected: false,
      soilDelta: 0,
      humidityDelta: 0,
    );
  }

  final soilDelta = soil - previous.soilMoisture;
  final humidityDelta =
      humidity != null ? humidity - previous.humidity : 0.0;

  final detected = soilDelta >= kSoilMoistureWateringDelta ||
      (soilDelta >= kSoilMoistureCombinedDelta &&
          humidityDelta >= kHumidityCombinedDelta);

  return WateringDetectionResult(
    detected: detected,
    soilDelta: soilDelta,
    humidityDelta: humidityDelta,
  );
}

PlantSensorBaseline baselineFromSnapshot(RealtimeSensorSnapshot snapshot) {
  return PlantSensorBaseline(
    soilMoisture: snapshot.soilMoisture ?? 0,
    humidity: snapshot.humidity ?? 0,
    recordedAt: (snapshot.timestamp ?? DateTime.now()).toIso8601String(),
  );
}

bool isWateringCooldownActive(String? lastDetectedAtIso) {
  if (lastDetectedAtIso == null || lastDetectedAtIso.isEmpty) return false;
  final last = DateTime.tryParse(lastDetectedAtIso);
  if (last == null) return false;
  return DateTime.now().difference(last) < kWateringCooldown;
}
