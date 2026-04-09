import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/plant_mock_datasource.dart';
import '../../data/repositories/plant_repository_impl.dart';
import '../../domain/repositories/plant_repository.dart';
import '../../data/models/plant.dart';

final datasourceProvider = Provider((ref) => PlantMockDatasource());

final repositoryProvider = Provider<PlantRepository>((ref) {
  return PlantRepositoryImpl(ref.read(datasourceProvider));
});

final plantsProvider = FutureProvider<List<Plant>>((ref) async {
  final repo = ref.read(repositoryProvider);
  return repo.getAllPlants();
});