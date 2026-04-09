class Range {
  final double min;
  final double max;

  const Range(this.min, this.max);

  factory Range.fromList(List? list) {
    if (list == null || list.length < 2) {
      return const Range(0, 0);
    }
    return Range(
      (list[0] as num).toDouble(),
      (list[1] as num).toDouble(),
    );
  }
}

class ComfortZones {
  final Range humidity;
  final Range temperature;
  final Range light;
  final Range soilMoisture;

  const ComfortZones({
    required this.humidity,
    required this.temperature,
    required this.light,
    required this.soilMoisture,
  });

  factory ComfortZones.fromJson(Map<String, dynamic> json) {
    return ComfortZones(
      humidity: Range.fromList(json['humidity']),
      temperature: Range.fromList(json['temperature']),
      light: Range.fromList(json['light']),
      soilMoisture: Range.fromList(json['soilMoisture']),
    );
  }
}