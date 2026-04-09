import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/plant_providers.dart';

class PlantsScreen extends ConsumerWidget {
  const PlantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Plants')),
      body: plantsAsync.when(
        data: (plants) {
          return ListView.builder(
            itemCount: plants.length,
            itemBuilder: (_, i) {
              final plant = plants[i];
              return ListTile(
                title: Text(plant.name),
                subtitle: Text('Health: ${plant.health}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}