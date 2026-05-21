import '../models/plant.dart';

abstract class PlantDatasource {
  Future<List<Plant>> getPlants();
}