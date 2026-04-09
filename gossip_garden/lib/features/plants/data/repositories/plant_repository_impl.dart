import '../../domain/repositories/plant_repository.dart';
import '../datasources/plant_mock_datasource.dart';
import '../models/plant_model.dart';

class PlantRepositoryImpl implements PlantRepository {
  final PlantMockDatasource datasource;

  PlantRepositoryImpl(this.datasource);

  @override
  Future<List<Plant>> getAllPlants() async {
    final raw = await datasource.getRawPlants();
    return raw.map((e) => Plant.fromJson(e)).toList();
  }
}