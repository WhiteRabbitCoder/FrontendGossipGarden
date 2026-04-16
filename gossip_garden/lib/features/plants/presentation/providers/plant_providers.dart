import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/plant_datasource.dart';
import '../../data/datasources/plant_api_datasource.dart';
import '../../data/datasources/sensor_stream_datasource.dart';
import '../../data/repositories/plant_repository_impl.dart';
import '../../domain/repositories/plant_repository.dart';
import '../../data/models/plant.dart';
import '../../data/models/realtime_sensor_snapshot.dart';

final datasourceProvider = Provider<PlantDatasource>(
  (ref) => PlantApiDatasource(),
);

final repositoryProvider = Provider<PlantRepository>(
  (ref) => PlantRepositoryImpl(ref.read(datasourceProvider)),
);

final sensorStreamDatasourceProvider = Provider<SensorStreamDatasource>(
  (ref) => SensorStreamDatasource(),
);

final plantsProvider = FutureProvider<List<Plant>>((ref) async {
  final timer = Timer.periodic(const Duration(seconds: 5), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  return ref.read(repositoryProvider).getAllPlants();
});

final plantRealtimeSensorProvider =
    StreamProvider.family<RealtimeSensorSnapshot, int>((ref, plantId) {
  return ref.read(sensorStreamDatasourceProvider).watchPlantSensor(plantId);
});
