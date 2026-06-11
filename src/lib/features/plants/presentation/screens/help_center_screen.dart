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
      question: '¿Cómo agrego una nueva planta?',
      answer:
          'Ve a Mi Jardín y pulsa el icono "+" en la parte superior derecha. '
          'Podrás identificarla con la cámara o buscarla por nombre para añadirla a tu colección.',
    ),
    (
      question: '¿Cómo conecto o reconecto el sensor?',
      answer:
          'Ve a Perfil → Ajustes → SENSORES → Mis sensores. Allí revisas el estado de cada '
          'planta, diagnosticas fallas y reconfiguras el WiFi del chip. También puedes entrar '
          'desde el perfil de una planta, en la sección "Estado del sensor".',
    ),
    (
      question: '¿Cómo funcionan las notificaciones y recordatorios?',
      answer:
          'En Perfil → Ajustes → NOTIFICACIONES activa avisos push, correo semanal y '
          'recordatorios de cuidado. En Inicio, la campana muestra una checklist con las '
          'acciones urgentes por planta; al marcarlas se actualiza el estado en su perfil.',
    ),
    (
      question: '¿Cómo cambio mi contraseña o datos personales?',
      answer:
          'Ve a Perfil → Ajustes → CUENTA → Información personal. Allí puedes actualizar '
          'tu nombre, avatar, bio y contraseña.',
    ),
    (
      question: '¿Cómo invito a un amigo jardinero?',
      answer:
          'En Mi Jardín pulsa el icono de invitar (persona con +). Comparte tu código o '
          'enlace de invitación, o únete al jardín de otro amigo introduciendo su código.',
    ),
    (
      question: '¿Quién puede ver mi jardín?',
      answer:
          'Ve a Perfil → Ajustes → PRIVACIDAD Y SEGURIDAD → Visibilidad del perfil. '
          'Puedes elegir si tu jardín es público, visible solo para amigos o privado. '
          'En Privacidad de datos gestionas el uso de lecturas de sensores y analítica.',
    ),
    (
      question: '¿Dónde veo mis logros?',
      answer:
          'En tu Perfil encontrarás la sección "Mis Logros". Toca cualquier logro para ver '
          'tu progreso, cómo desbloquearlo y qué acciones de la app lo registran.',
    ),
    (
      question: '¿Puedo tener varias plantas en mi jardín?',
      answer:
          'Sí. Puedes agregar tantas plantas como quieras. Cada una tendrá su propio '
          'perfil, chat, sensores y estado de salud independiente.',
    ),
    (
      question: '¿Cómo contacto al soporte?',
      answer:
          'Ve a Perfil → Ajustes → SOPORTE → Contactar soporte. Escríbenos tu consulta '
          'y te responderemos en menos de 24 horas. También puedes valorar la app desde '
          'Calificar la app, que abre Google Play Store.',
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
                    '¿No encuentras lo que buscas? Ve a Ajustes → SOPORTE → Contactar soporte.',
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
