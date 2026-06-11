import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/achievements/achievement_progress_storage.dart';
import '../../data/models/achievement.dart';
import '../../data/models/comfort_zones.dart';
import '../../data/models/friend_garden.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../data/models/sensors.dart';

// TODO(backend): reemplazar con GET /api/v1/friends/{id}/garden

const _mateoPotos = Plant(
  id: 'f1',
  name: 'Potos de Mateo',
  species: 'Epipremnum Aureum',
  image: '',
  personality: PlantPersonality.playful,
  health: 92.0,
  mood: PlantMood.happy,
  lastWatered: 'Hace 1 día',
  sensors: Sensors(
    humidity: 55.0,
    temperature: 23.0,
    light: 2800.0,
    soilMoisture: 48.0,
  ),
  sensorStatus: SensorStatus.online,
  confidence: ConfidenceLevel.high,
  actions: [],
  insights: ['Mateo me cuida muy bien, ¡crezco rápido!'],
  comfortZones: ComfortZones(
    humidity: Range(40, 70),
    temperature: Range(18, 28),
    light: Range(800, 3000),
    soilMoisture: Range(30, 60),
  ),
);

const _mateoSansevieria = Plant(
  id: 'f2',
  name: 'Lengua de suegra',
  species: 'Sansevieria Trifasciata',
  image: '',
  personality: PlantPersonality.wise,
  health: 88.0,
  mood: PlantMood.perfect,
  lastWatered: 'Hace 5 días',
  sensors: Sensors(
    humidity: 35.0,
    temperature: 22.0,
    light: 3200.0,
    soilMoisture: 22.0,
  ),
  sensorStatus: SensorStatus.online,
  confidence: ConfidenceLevel.high,
  actions: [],
  insights: ['Soy resistente y feliz en este rincón soleado.'],
  comfortZones: ComfortZones(
    humidity: Range(20, 50),
    temperature: Range(15, 30),
    light: Range(1000, 5000),
    soilMoisture: Range(10, 35),
  ),
);

const _mateoMonstera = Plant(
  id: 'f3',
  name: 'Monstera Mini',
  species: 'Monstera Adansonii',
  image: '',
  personality: PlantPersonality.dramatic,
  health: 81.0,
  mood: PlantMood.happy,
  lastWatered: 'Hace 2 días',
  sensors: Sensors(
    humidity: 62.0,
    temperature: 24.0,
    light: 1900.0,
    soilMoisture: 42.0,
  ),
  sensorStatus: SensorStatus.degraded,
  confidence: ConfidenceLevel.medium,
  actions: [],
  insights: ['Mis hojas nuevas son preciosas este mes.'],
  comfortZones: ComfortZones(
    humidity: Range(50, 75),
    temperature: Range(20, 28),
    light: Range(1000, 2500),
    soilMoisture: Range(35, 55),
  ),
);

const _mateoStats = AchievementStats(
  wateringsCount: 10,
  identificationsCount: 8,
  chatMessagesCount: 52,
  gardenVisitsCount: 18,
  loginStreak: 7,
  sensorSetupCompleted: true,
);

const _mateoFavorites = ['f1', 'f2', 'f3'];

final friendGardensProvider = Provider<List<FriendGarden>>((ref) {
  final storage = AchievementProgressStorage();
  final mateoPlants = [_mateoPotos, _mateoSansevieria, _mateoMonstera];

  return [
    FriendGarden(
      id: 'mateo',
      displayName: 'Mateo',
      featuredPlants: mateoPlants,
      achievements: storage.buildProgressList(
        stats: _mateoStats,
        plants: mateoPlants,
        favoritePlantIds: _mateoFavorites,
      ),
    ),
  ];
});

final friendGardenProvider = Provider.family<FriendGarden?, String>((ref, id) {
  final gardens = ref.watch(friendGardensProvider);
  for (final garden in gardens) {
    if (garden.id == id) return garden;
  }
  return null;
});
