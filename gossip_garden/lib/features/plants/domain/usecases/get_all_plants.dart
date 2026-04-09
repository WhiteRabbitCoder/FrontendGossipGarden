import '../repositories/plant_repository.dart';
import '../../data/models/plant_model.dart';

class GetAllPlants {
  final PlantRepository repository;

  GetAllPlants(this.repository);

  Future<List<Plant>> call() {
    return repository.getAllPlants();
  }
}