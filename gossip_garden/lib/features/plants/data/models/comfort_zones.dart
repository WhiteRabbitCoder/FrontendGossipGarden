class Range {
  final double min;
  final double max;

  Range({required this.min, required this.max});

  factory Range.fromList(List? list) {
    if (list == null || list.length < 2) {
      return Range(min: 0, max: 0);
    }

    return Range(
      min: (list[0] as num?)?.toDouble() ?? 0,
      max: (list[1] as num?)?.toDouble() ?? 0,
    );
  }

  List<double> toList() => [min, max];
}

class ComfortZones {
  final Range humidity;
  final Range temperature;
  final Range light;
  final Range soilMoisture;

  ComfortZones({
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