


// confirmar, todo esto está malo //
import '../repositories/plant_repository.dart';
import '../../data/models/plant.dart';

class GetAllPlants {
  final PlantRepository repository;

  GetAllPlants(this.repository);

  Future<List<Plant>> call() {
    return repository.getAllPlants();
  }
}
