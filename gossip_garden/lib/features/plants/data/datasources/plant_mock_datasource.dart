class PlantMockDatasource {
  Future<List<Plant>> getPlants() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final raw = [
      {
        "id": "1",
        "name": "Monstera",
        "species": "Monstera Deliciosa",
        "image": "assets/plant_hero.png",
        "personality": "wise",
        "health": 78,
        "mood": "thirsty",
        "lastWatered": "2 días",
        "sensors": {
          "humidity": 45,
          "temperature": 22,
          "light": 650,
          "soilMoisture": 28
        },
        "sensorStatus": "online",
        "confidence": "high",
        "actions": [
          {
            "id": "a1",
            "type": "water",
            "urgency": "today",
            "message": "Oye… tengo un poquito de sed 🌱"
          }
        ],
        "insights": ["Mi humedad ha estado algo loca 😅"],
        "comfortZones": {
          "humidity": [50, 70],
          "temperature": [18, 27],
          "light": [400, 1000],
          "soilMoisture": [40, 65]
        }
      }
    ];

    return raw.map((e) => Plant.fromJson(e)).toList();
  }
}