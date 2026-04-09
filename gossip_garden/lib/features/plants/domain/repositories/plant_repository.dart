import '../../data/models/plant.dart';

abstract class PlantRepository {
  Future<List<Plant>> getAllPlants();
}