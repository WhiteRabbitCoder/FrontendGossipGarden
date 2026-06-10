import 'package:flutter/material.dart';
import 'package:gossip_garden/core/theme/garden_colors.dart';
import '../../data/models/plant.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: GardenColors.dustLight, width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildPlantAvatar(plant),
              const SizedBox(width: 16),
              Expanded(child: _buildPlantInfo(plant)),
              _buildHealthBadge(plant),
            ],
          ),
        ),
      ),
    );  // card, revisar 
  }
  
  Widget _buildPlantAvatar(Plant plant) {
    return Container( 
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: GardenColors.creamLight, // GardenColors.creamLight
        shape: BoxShape.circle,
      ),
      child: plant.image.isNotEmpty
          ? ClipOval(
              child: Image.network(
                plant.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  _getPlantIcon(plant.species),
                  color: GardenColors.leafDark, // GardenColors.leafDark
                  size: 24,
                ),
              ),
            )
          : Icon(
              _getPlantIcon(plant.species),
              color: GardenColors.leafDark, // GardenColors.leafDark
              size: 24,
            ),
    );
  }

  IconData _getPlantIcon(String species) {
    final lower = species.toLowerCase();
    if (lower.contains('echeveria') || lower.contains('suculenta')) {
      return Icons.local_florist_outlined;
    }
    if (lower.contains('ficus')) {
      return Icons.park_outlined;
    }
    return Icons.eco_outlined;
  }

  Widget _buildPlantInfo(Plant plant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          plant.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          plant.species,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Text(
          plant.insights.isNotEmpty ? plant.insights.first : 'Todo bien',
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildHealthBadge(Plant plant) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: plant.health > 70
            ? Colors.green.withOpacity(0.1)
            : plant.health > 40
                ? Colors.orange.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: plant.health > 70
              ? Colors.green.withOpacity(0.25)
              : plant.health > 40
                  ? Colors.orange.withOpacity(0.25)
                  : Colors.red.withOpacity(0.25),
        ),
      ),
      child: Text(
        '${plant.health.toInt()}%',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: plant.health > 70
              ? Colors.green
              : plant.health > 40
                  ? Colors.orange
                  : Colors.red,
        ),
      ),
    );
  }
}
