import 'plant_enums.dart';

class PlantAction {
  final String id;
  final PlantActionType type;
  final ActionUrgency urgency;
  final String message;
  final String? plantId;

  PlantAction({
    required this.id,
    required this.type,
    required this.urgency,
    required this.message,
    this.plantId,
  });

  factory PlantAction.fromJson(Map<String, dynamic> json) {
    return PlantAction(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      plantId: json['plantId'],
      type: enumFromString(
        PlantActionType.values,
        json['type'],
        PlantActionType.water,
      ),
      urgency: enumFromString(
        ActionUrgency.values,
        json['urgency'],
        ActionUrgency.later,
      ),
    );
  }
}