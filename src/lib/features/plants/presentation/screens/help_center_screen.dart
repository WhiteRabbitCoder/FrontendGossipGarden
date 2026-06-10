import 'package:flutter/material.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const _faqs = [
    (
      question: '¿Cómo identifico una planta?',
      answer:
          'Ve a tu jardín, pulsa el botón "+" y selecciona "Identificar planta". '
          'Toma una foto clara de las hojas y la app te sugerirá la especie.',
    ),
    (
      question: '¿Cómo conecto el sensor de mi planta?',
      answer:
          'Durante el onboarding, elige la red WiFi de tu hogar e introduce la contraseña. '
          'El chip se conectará automáticamente a tu red.',
    ),
    (
      question: '¿Por qué no recibo notificaciones?',
      answer:
          'Revisa que las notificaciones push estén activadas en Ajustes. '
          'También comprueba los permisos de la app en la configuración de tu dispositivo.',
    ),
    (
      question: '¿Cómo cambio mi contraseña?',
      answer:
          'Ve a Ajustes → Información personal. Allí puedes actualizar tu contraseña '
          'junto con tu nombre y avatar.',
    ),
    (
      question: '¿Puedo tener varias plantas en mi jardín?',
      answer:
          'Sí. Puedes agregar tantas plantas como quieras. Cada una tendrá su propio '
          'perfil, chat y datos de sensores.',
    ),
  ];

  final Set<int> _expanded = {};

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
              'Centro de ayuda',
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Preguntas frecuentes y guías',
              style: GardenTextStyles.label.copyWith(color: GardenColors.inkSoft),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GardenColors.leafGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GardenColors.leafGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: GardenColors.leafDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¿No encuentras lo que buscas? Contacta con nuestro equipo de soporte.',
                    style: GardenTextStyles.bodySmall.copyWith(color: GardenColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'PREGUNTAS FRECUENTES',
            style: GardenTextStyles.label.copyWith(
              color: GardenColors.inkSoft,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_faqs.length, (index) {
            final faq = _faqs[index];
            final isExpanded = _expanded.contains(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GardenColors.creamPaper),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    iconColor: GardenColors.leafDark,
                    collapsedIconColor: GardenColors.inkSoft,
                    title: Text(
                      faq.question,
                      style: GardenTextStyles.bodySmall.copyWith(
                        color: GardenColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    initiallyExpanded: isExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        if (expanded) {
                          _expanded.add(index);
                        } else {
                          _expanded.remove(index);
                        }
                      });
                    },
                    children: [
                      Text(
                        faq.answer,
                        style: GardenTextStyles.bodySmall.copyWith(
                          color: GardenColors.inkSoft,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
