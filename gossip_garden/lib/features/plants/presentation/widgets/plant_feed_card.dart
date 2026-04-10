import 'package:flutter/material.dart';
// Cámbialo por la ruta donde está tu clase Plant que definimos antes
import '../../data/models/plant.dart'; 

class PlantFeedCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final bool isCelebrating;

  const PlantFeedCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.isCelebrating = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        elevation: 1, // Le damos un toque de profundidad
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'plantHero_${plant.id}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withOpacity(0.08),
                    ),
                    padding: const EdgeInsets.all(10),
                    // Usamos un placeholder por si la URL falla
                    child: Image.network(
                      plant.image,
                      errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.eco, color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plant.insights.isNotEmpty
                            ? plant.insights.first
                            : 'Todo está bien 🌿',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withOpacity(0.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}