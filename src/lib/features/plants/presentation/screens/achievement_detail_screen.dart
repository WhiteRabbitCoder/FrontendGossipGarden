import 'package:flutter/material.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';
import '../../data/models/achievement.dart';

class AchievementDetailScreen extends StatelessWidget {
  final AchievementProgress progress;

  const AchievementDetailScreen({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final def = progress.definition;
    final percent = (progress.ratio * 100).round();

    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const GardenIcon(asset: GardenIcons.back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              def.title,
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              progress.unlocked ? 'Logro desbloqueado' : 'En progreso',
              style: GardenTextStyles.label.copyWith(
                color: progress.unlocked ? GardenColors.leafDark : GardenColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GardenColors.creamPaper),
            ),
            child: Column(
              children: [
                GardenIcon(
                  asset: GardenIcons.achievementAsset(def.id),
                  size: 56,
                  opacity: progress.unlocked ? 1.0 : 0.5,
                ),
                const SizedBox(height: 12),
                Text(
                  def.description,
                  style: GardenTextStyles.bodySmall.copyWith(
                    color: GardenColors.inkSoft,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Avance',
                      style: GardenTextStyles.label.copyWith(
                        color: GardenColors.inkSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${progress.displayCurrent}/${progress.goal} · $percent%',
                      style: GardenTextStyles.bodySmall.copyWith(
                        color: GardenColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.ratio,
                    minHeight: 10,
                    backgroundColor: GardenColors.creamLight,
                    color: progress.unlocked
                        ? GardenColors.golden
                        : GardenColors.leafGreen,
                  ),
                ),
                if (progress.unlocked) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: GardenColors.leafGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GardenIcon(
                          asset: GardenIcons.logroTrofeo,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '¡Logro conseguido!',
                          style: GardenTextStyles.label.copyWith(
                            color: GardenColors.leafDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InfoCard(
            title: 'Cómo se desbloquea',
            iconAsset: GardenIcons.logroExplorador,
            body: def.howToEarn,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Cómo se registra el avance',
            iconAsset: GardenIcons.info,
            body: def.trackingSource,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String iconAsset;
  final String body;

  const _InfoCard({
    required this.title,
    required this.iconAsset,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GardenColors.creamPaper),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GardenIcon(asset: iconAsset, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GardenTextStyles.bodySmall.copyWith(
                  color: GardenColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GardenTextStyles.bodySmall.copyWith(
              color: GardenColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
