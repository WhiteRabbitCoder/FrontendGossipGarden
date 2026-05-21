class Sensors {
  final double humidity;
  final double temperature;
  final double light;
  final double soilMoisture;

  const Sensors({
    required this.humidity,
    required this.temperature,
    required this.light,
    required this.soilMoisture,
  });

  factory Sensors.fromJson(Map<String, dynamic> json) {
    return Sensors(
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
      light: (json['light'] as num?)?.toDouble() ?? 0,
      soilMoisture: (json['soilMoisture'] as num?)?.toDouble() ?? 0,
    );
  }
}