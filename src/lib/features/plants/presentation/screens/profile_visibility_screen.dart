import 'package:flutter/material.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';

enum ProfileVisibility { public, friends, private }

class ProfileVisibilityScreen extends StatefulWidget {
  const ProfileVisibilityScreen({super.key});

  @override
  State<ProfileVisibilityScreen> createState() => _ProfileVisibilityScreenState();
}

class _ProfileVisibilityScreenState extends State<ProfileVisibilityScreen> {
  ProfileVisibility _visibility = ProfileVisibility.friends;
  bool _showPlantHealth = true;
  bool _showAchievements = true;

  @override
  Widget build(BuildContext context) {
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
              'Visibilidad del perfil',
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Quién puede ver tu jardín',
              style: GardenTextStyles.label.copyWith(color: GardenColors.inkSoft),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text(
            'QUIÉN PUEDE VER TU JARDÍN',
            style: GardenTextStyles.label.copyWith(
              color: GardenColors.inkSoft,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _VisibilityOption(
            iconAsset: GardenIcons.eyeOpen,
            title: 'Público',
            subtitle: 'Cualquier usuario puede ver tu jardín',
            selected: _visibility == ProfileVisibility.public,
            onTap: () => setState(() => _visibility = ProfileVisibility.public),
          ),
          const SizedBox(height: 12),
          _VisibilityOption(
            iconAsset: GardenIcons.friendPlants,
            title: 'Solo amigos',
            subtitle: 'Únicamente tus contactos del jardín',
            selected: _visibility == ProfileVisibility.friends,
            onTap: () => setState(() => _visibility = ProfileVisibility.friends),
          ),
          const SizedBox(height: 12),
          _VisibilityOption(
            iconAsset: GardenIcons.lock,
            title: 'Privado',
            subtitle: 'Solo tú puedes ver tu jardín',
            selected: _visibility == ProfileVisibility.private,
            onTap: () => setState(() => _visibility = ProfileVisibility.private),
          ),
          const SizedBox(height: 28),
          Text(
            'QUÉ SE MUESTRA',
            style: GardenTextStyles.label.copyWith(
              color: GardenColors.inkSoft,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _ToggleRow(
            title: 'Salud de las plantas',
            subtitle: 'Porcentaje y estado de cada planta',
            value: _showPlantHealth,
            onChanged: (v) => setState(() => _showPlantHealth = v),
          ),
          const SizedBox(height: 12),
          _ToggleRow(
            title: 'Logros',
            subtitle: 'Tus medallas y progreso de jardinero',
            value: _showAchievements,
            onChanged: (v) => setState(() => _showAchievements = v),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preferencias de visibilidad guardadas.')),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GardenColors.leafDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              'Guardar preferencias',
              style: GardenTextStyles.title.copyWith(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? GardenColors.leafGreen : GardenColors.creamPaper,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: GardenColors.creamLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: GardenIcon(asset: iconAsset, size: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GardenTextStyles.bodySmall.copyWith(
                      color: GardenColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GardenTextStyles.label.copyWith(
                      color: GardenColors.inkSoft,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? GardenColors.leafDark : GardenColors.inkSoft,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GardenColors.creamPaper),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GardenTextStyles.bodySmall.copyWith(
                    color: GardenColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GardenTextStyles.label.copyWith(
                    color: GardenColors.inkSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: GardenColors.leafDark,
          ),
        ],
      ),
    );
  }
}
