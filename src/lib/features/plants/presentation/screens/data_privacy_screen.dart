import 'package:flutter/material.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';

class DataPrivacyScreen extends StatefulWidget {
  const DataPrivacyScreen({super.key});

  @override
  State<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends State<DataPrivacyScreen> {
  bool _shareSensorData = true;
  bool _usageAnalytics = true;
  bool _personalizedTips = true;

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
              'Privacidad de datos',
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Gestiona cómo usamos tu información',
              style: GardenTextStyles.label.copyWith(color: GardenColors.inkSoft),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _InfoCard(
            iconAsset: GardenIcons.shield,
            body:
                'Gossip Garden usa tus datos para cuidar tus plantas, personalizar consejos '
                'y mejorar la app. Nunca vendemos tu información a terceros.',
          ),
          const SizedBox(height: 20),
          Text(
            'PREFERENCIAS',
            style: GardenTextStyles.label.copyWith(
              color: GardenColors.inkSoft,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _ToggleCard(
            title: 'Datos de sensores',
            subtitle: 'Permite usar lecturas de humedad, luz y temperatura',
            value: _shareSensorData,
            onChanged: (v) => setState(() => _shareSensorData = v),
          ),
          const SizedBox(height: 12),
          _ToggleCard(
            title: 'Analítica de uso',
            subtitle: 'Nos ayuda a detectar errores y mejorar funciones',
            value: _usageAnalytics,
            onChanged: (v) => setState(() => _usageAnalytics = v),
          ),
          const SizedBox(height: 12),
          _ToggleCard(
            title: 'Consejos personalizados',
            subtitle: 'Recomendaciones basadas en tu jardín y hábitos',
            value: _personalizedTips,
            onChanged: (v) => setState(() => _personalizedTips = v),
          ),
          const SizedBox(height: 24),
          Text(
            'TUS DERECHOS',
            style: GardenTextStyles.label.copyWith(
              color: GardenColors.inkSoft,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            iconAsset: GardenIcons.share,
            title: 'Descargar mis datos',
            subtitle: 'Recibe una copia de tu información',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Solicitud registrada. Te avisaremos por correo.'),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionTile(
            iconAsset: GardenIcons.info,
            title: 'Solicitar eliminación de datos',
            subtitle: 'Borra tu cuenta y toda tu información',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contacta con soporte para completar esta solicitud.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String iconAsset;
  final String body;

  const _InfoCard({required this.iconAsset, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GardenColors.creamPaper),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GardenIcon(asset: iconAsset, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              body,
              style: GardenTextStyles.bodySmall.copyWith(
                color: GardenColors.inkSoft,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
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

class _ActionTile extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
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
          border: Border.all(color: GardenColors.creamPaper),
        ),
        child: Row(
          children: [
            GardenIcon(asset: iconAsset, size: 20),
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
            const GardenIcon(asset: GardenIcons.forward, size: 20, opacity: 0.6),
          ],
        ),
      ),
    );
  }
}
