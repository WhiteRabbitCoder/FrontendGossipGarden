import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../../data/models/plant_enums.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';

/// Banner verde en el Dashboard que muestra cuántas plantas necesitan atención.
/// Conectado al [plantsProvider] para contar dinámicamente.
/// Cuando el backend esté listo, el conteo se actualizará automáticamente.
class SummaryBanner extends ConsumerWidget {
  final VoidCallback onAction;

  const SummaryBanner({super.key, required this.onAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);

    final needsAttentionCount = plantsAsync.maybeWhen(
      data: (plants) => plants
          .where((p) =>
              p.mood == PlantMood.thirsty ||
              p.mood == PlantMood.stressed ||
              p.mood == PlantMood.cold ||
              p.mood == PlantMood.hot)
          .length,
      orElse: () => 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: GardenColors.leafGreen,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(32),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(color: GardenColors.ink, width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: GardenColors.ink,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$needsAttentionCount plantas necesitan mimos',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pequeños cuidados diarios, grandes plantas felices.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: GardenColors.ink,
              side: const BorderSide(color: GardenColors.ink, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              textStyle: GardenTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Ir a mi jardín →'),
          ),
        ],
      ),
    );
  }
}
