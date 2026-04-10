import '../../domain/repositories/plant_repository.dart';
import '../datasources/plant_datasource.dart';
import '../models/plant.dart';

class PlantRepositoryImpl implements PlantRepository {
  final PlantDatasource datasource;

  PlantRepositoryImpl(this.datasource);

  @override
  Future<List<Plant>> getAllPlants() {
    return datasource.getPlants();
  }
}