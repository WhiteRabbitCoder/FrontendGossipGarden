import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';

class PlantsScreen extends ConsumerWidget {
  const PlantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Plantas 🌱'),
      ),
      body: plantsAsync.when(
        data: (plants) => ListView.builder(
          itemCount: plants.length,
          itemBuilder: (context, index) {
            final plant = plants[index];
            return ListTile(
              title: Text(plant.name),
              subtitle: Text(plant.species),
              trailing: Text('${plant.health}%'),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}