class RealtimeSensorSnapshot {
  final int? sensorDataId;
  final int plantId;
  final DateTime? timestamp;
  final double? temperature;
  final double? humidity;
  final double? soilMoisture;
  final double? light;

  const RealtimeSensorSnapshot({
    required this.sensorDataId,
    required this.plantId,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.light,
  });

  factory RealtimeSensorSnapshot.fromJson(Map<String, dynamic> json) {
    final data = json['sensor_data'] as Map<String, dynamic>?;
    final ts = data?['timestamp']?.toString();

    return RealtimeSensorSnapshot(
      sensorDataId: _toInt(data?['sensor_data_id']),
      plantId: _toInt(json['plant_id']) ?? 0,
      timestamp: ts == null ? null : DateTime.tryParse(ts),
      temperature: _toDouble(data?['temperature']),
      humidity: _toDouble(data?['humidity']),
      soilMoisture: _toDouble(data?['soil_moisture']),
      light: _toDouble(data?['light']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
