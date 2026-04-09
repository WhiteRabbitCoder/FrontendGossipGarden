import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/plant_mock_datasource.dart';
import '../../data/repositories/plant_repository_impl.dart';
import '../../domain/repositories/plant_repository.dart';
import '../../domain/usecases/get_all_plants.dart';
import '../../data/models/plant_model.dart';

final datasourceProvider = Provider((ref) => PlantMockDatasource());

final repositoryProvider = Provider<PlantRepository>((ref) {
  return PlantRepositoryImpl(ref.read(datasourceProvider));
});

final getPlantsProvider = Provider((ref) {
  return GetAllPlants(ref.read(repositoryProvider));
});

final plantsProvider = FutureProvider<List<Plant>>((ref) async {
  return ref.read(getPlantsProvider).call();
});