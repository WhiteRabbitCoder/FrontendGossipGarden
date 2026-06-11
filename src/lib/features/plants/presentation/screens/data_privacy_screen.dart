import 'package:flutter/material.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GardenColors.ink),
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
            icon: Icons.shield_outlined,
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
            icon: Icons.download_outlined,
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
            icon: Icons.delete_outline_rounded,
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
  final IconData icon;
  final String body;

  const _InfoCard({required this.icon, required this.body});

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
          Icon(icon, color: GardenColors.leafDark, size: 22),
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
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
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
            Icon(icon, color: GardenColors.ink, size: 20),
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
            const Icon(Icons.chevron_right_rounded, color: GardenColors.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }
}
