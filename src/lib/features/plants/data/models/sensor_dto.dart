class SensorDataResponse {
  final String id;
  final String sensorId;
  final String macAddress;
  final String plantId;
  final double temperatureC;
  final double humidityPct;
  final double soilMoisturePct;
  final double lightLux;
  final double healthScore;
  final String healthStatus;
  final DateTime timestamp;

  SensorDataResponse({
    required this.id,
    required this.sensorId,
    required this.macAddress,
    required this.plantId,
    required this.temperatureC,
    required this.humidityPct,
    required this.soilMoisturePct,
    required this.lightLux,
    required this.healthScore,
    required this.healthStatus,
    required this.timestamp,
  });

  factory SensorDataResponse.fromJson(Map<String, dynamic> json) {
    return SensorDataResponse(
      id: json['id'],
      sensorId: json['sensor_id'],
      macAddress: json['mac_address'],
      plantId: json['plant_id'],
      temperatureC: (json['temperature_c'] ?? 0.0).toDouble(),
      humidityPct: (json['humidity_pct'] ?? 0.0).toDouble(),
      soilMoisturePct: (json['soil_moisture_pct'] ?? 0.0).toDouble(),
      lightLux: (json['light_lux'] ?? 0.0).toDouble(),
      healthScore: (json['health_score'] ?? 0.0).toDouble(),
      healthStatus: json['health_status'] ?? 'unknown',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
