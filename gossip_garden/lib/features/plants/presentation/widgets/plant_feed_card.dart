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

    final bool hasAlert = plant.insights.isNotEmpty && plant.insights.first != 'Todo esta bien';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Hero(
                    tag: 'plantHero_${plant.id}',
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasAlert ? Colors.orange.shade50 : colorScheme.primary.withOpacity(0.08),
                        border: Border.all(
                          color: hasAlert ? Colors.orange.shade200 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: plant.image.isNotEmpty
                          ? Image.network(
                              plant.image,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.eco, color: hasAlert ? Colors.orange : Colors.green),
                            )
                          : Icon(Icons.eco, color: hasAlert ? Colors.orange : Colors.green),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plant.name,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (hasAlert)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plant.insights.isNotEmpty
                              ? plant.insights.first
                              : 'Todo esta bien',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: hasAlert ? Colors.orange.shade700 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
