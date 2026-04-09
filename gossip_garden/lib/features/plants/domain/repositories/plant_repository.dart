import '../../data/models/plant_model.dart';

abstract class PlantRepository {
  Future<List<Plant>> getAllPlants();
}