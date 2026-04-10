import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../widgets/plant_feed_card.dart'; 

class PlantsScreen extends ConsumerWidget {
  const PlantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), 
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        title: const Text(
          'Mis Plantas 🌱',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: plantsAsync.when(
        data: (plants) => ListView.builder(
          padding: const EdgeInsets.all(16), 
          itemCount: plants.length,
          itemBuilder: (context, index) {
            final plant = plants[index];
            
            return PlantFeedCard(
              plant: plant,
              onTap: () {
                // Por ahora solo un print para que no de error
                print('Navegando a: ${plant.name}');
                // Aquí podrías usar Navigator.push para ir al perfil
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}