class PlantMockDatasource {
  Future<List<Map<String, dynamic>>> getRawPlants() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        "id": "1",
        "name": "Monstera",
        "health": 78,
        "mood": "thirsty",
        "sensors": {
          "humidity": 45,
          "temperature": 22,
          "light": 650,
          "soilMoisture": 28
        },
        "comfortZones": {
          "humidity": [50, 70],
          "temperature": [18, 27],
          "light": [400, 1000],
          "soilMoisture": [40, 65]
        }
      }
    ];
  }
}