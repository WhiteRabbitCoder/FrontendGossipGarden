import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/urgent_plant_task.dart';
import 'plant_providers.dart';

final urgentTasksProvider = Provider<List<UrgentPlantTask>>((ref) {
  final plantsAsync = ref.watch(plantsProvider);
  return plantsAsync.maybeWhen(
    data: (plants) {
      final tasks = plants.expand(deriveUrgentTasks).toList();
      tasks.sort((a, b) => a.urgency.index.compareTo(b.urgency.index));
      return tasks;
    },
    orElse: () => const [],
  );
});

final pendingUrgentTasksCountProvider = Provider<int>((ref) {
  return ref.watch(urgentTasksProvider).length;
});
