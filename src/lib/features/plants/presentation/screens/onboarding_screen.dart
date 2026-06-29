import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gossip_garden/core/theme/garden_colors.dart';
import 'package:gossip_garden/core/theme/garden_icons.dart';
import 'package:gossip_garden/core/widgets/garden_icon.dart';
import 'package:gossip_garden/features/plants/presentation/providers/navigation_provider.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';
import 'package:gossip_garden/features/plants/presentation/screens/plant_identify_screen.dart';
import 'package:gossip_garden/features/plants/presentation/views/sensor_setup_view.dart';

enum OnboardingStep { wow, checklist, identify, sensor, config }

final notificationPreferenceProvider = StateProvider<String>((ref) => 'important');

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with TickerProviderStateMixin {
  OnboardingStep _step = OnboardingStep.wow;

  bool _isPlantIdentified = false;
  bool _isSensorConnected = false;
  bool _isSensorSkipped = false;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  late AnimationController _staggerController;
  late List<Animation<double>> _iconFadeAnims;
  late List<Animation<Offset>> _iconSlideAnims;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _staggerController = AnimationController(duration: const Duration(milliseconds: 900), vsync: this)..forward();
    _iconFadeAnims = List.generate(3, (i) {
      final start = i * 0.25;
      final end = start + 0.55;
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _staggerController, curve: Interval(start, end.clamp(0, 1), curve: Curves.easeOut)));
    });
    _iconSlideAnims = List.generate(3, (i) {
      final start = i * 0.25;
      final end = start + 0.55;
      return Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _staggerController, curve: Interval(start, end.clamp(0, 1), curve: Curves.easeOutBack)));
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Widget _buildChecklistStep() {
    final canContinue = _isPlantIdentified && (_isSensorConnected || _isSensorSkipped);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Prepara tu jardín',
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: GardenColors.ink,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Completa estos pasos para comenzar a escuchar a tus plantas.',
          style: TextStyle(fontSize: 15, color: GardenColors.inkSoft),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        _buildChecklistItem(
          title: 'Reconocer tu primera planta',
          isDone: _isPlantIdentified,
          onTap: () => setState(() => _step = OnboardingStep.identify),
          iconAsset: GardenIcons.addPlant,
          color: GardenColors.leafGreen,
        ),
        const SizedBox(height: 16),

        _buildChecklistItem(
          title: 'Conectar Sensor Gossip Garden',
          isDone: _isSensorConnected,
          isSkipped: _isSensorSkipped,
          onTap: () => setState(() => _step = OnboardingStep.sensor),
          onSkip: () => setState(() => _isSensorSkipped = true),
          iconAsset: GardenIcons.logroSensores,
          color: GardenColors.potOrange,
        ),
        const SizedBox(height: 40),

        ElevatedButton(
          onPressed: canContinue ? () => setState(() => _step = OnboardingStep.config) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: GardenColors.heartRed,
            disabledBackgroundColor: GardenColors.heartRed.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            minimumSize: const Size(double.infinity, 60),
            elevation: canContinue ? 4 : 0,
            shadowColor: GardenColors.heartRed.withValues(alpha: 0.4),
          ),
          child: const Text(
            'Continuar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required bool isDone,
    bool isSkipped = false,
    required VoidCallback onTap,
    VoidCallback? onSkip,
    required String iconAsset,
    required Color color,
  }) {
    final statusColor = isDone ? GardenColors.leafGreen : (isSkipped ? GardenColors.dustLight : GardenColors.ink);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isDone ? color.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDone ? color : GardenColors.ink.withValues(alpha: 0.2), width: isDone ? 2.5 : 2),
        boxShadow: [
          BoxShadow(
            color: (isDone ? color : GardenColors.ink).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: (isDone || isSkipped) ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: isDone
                      ? Container(
                          key: const ValueKey('done'),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: GardenColors.leafGreen, shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: Colors.white, size: 20),
                        )
                      : Container(
                          key: const ValueKey('pending'),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: statusColor, width: 2),
                          ),
                          child: isSkipped
                              ? Icon(Icons.close, color: GardenColors.dustLight, size: 20)
                              : GardenIcon(asset: iconAsset, size: 20, color: statusColor),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSkipped ? GardenColors.inkSoft : GardenColors.ink,
                          decoration: isSkipped ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (!isDone && onSkip != null && !isSkipped) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: onSkip,
                          child: const Text('Omitir (No tengo sensor)', style: TextStyle(fontSize: 13, color: GardenColors.potOrange, fontWeight: FontWeight.w600)),
                        )
                      ] else if (isSkipped) ...[
                         const SizedBox(height: 8),
                         GestureDetector(
                          onTap: () => setState(() => _isSensorSkipped = false),
                          child: const Text('Deshacer', style: TextStyle(fontSize: 13, color: GardenColors.inkSoft, fontWeight: FontWeight.w600)),
                        )
                      ]
                    ],
                  ),
                ),
                if (!isDone && !isSkipped)
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: GardenColors.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildWowStep() {
    final icons = [
      GardenIcons.water,
      GardenIcons.sun,
      GardenIcons.thermostat,
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: child,
          ),
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: GardenColors.leafDark.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                'images/logo_no_text.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Íconos con animación staggered
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(icons.length, (i) {
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 24),
              child: FadeTransition(
                opacity: _iconFadeAnims[i],
                child: SlideTransition(
                  position: _iconSlideAnims[i],
                  child: GardenIcon(asset: icons[i], size: 32),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        const Text(
          'Tus plantas tienen algo que decirte....',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: GardenColors.ink),
        ),
        const SizedBox(height: 32),
        _buildAppBasics(),
        const SizedBox(height: 48),
        _primaryButton('Comenzar', () {
          // Reiniciar stagger para verlo de nuevo si el usuario regresa
          _staggerController
            ..reset()
            ..forward();
          setState(() => _step = OnboardingStep.checklist);
        }),
      ],
    );
  }


  Widget _radioOptionRich({
    required String value,
    required String selected,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => ref.read(notificationPreferenceProvider.notifier).state = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? iconColor : GardenColors.dustLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? iconColor : GardenColors.dustLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : GardenColors.inkSoft, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: GardenColors.ink)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: GardenColors.inkSoft)),
                ],
              ),
            ),
            if (isSelected)
               Icon(Icons.check_circle_rounded, color: iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigStep(NavigationNotifier nav) {
    final selected = ref.watch(notificationPreferenceProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const GardenIcon(asset: GardenIcons.notification, size: 48),
        const SizedBox(height: 16),
        const Text(
          'Notificaciones',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
              color: GardenColors.ink),
        ),
        const SizedBox(height: 6),
        const Text(
          '¿Cuándo quieres que tus plantas te hablen?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: GardenColors.inkSoft),
        ),
        const SizedBox(height: 28),
        _radioOptionRich(
          value: 'important',
          selected: selected,
          icon: Icons.notifications_active_rounded,
          iconColor: GardenColors.leafDark,
          title: 'Solo importantes',
          subtitle: 'Alertas de riego urgente y enfermedades',
        ),
        const SizedBox(height: 12),
        _radioOptionRich(
          value: 'all',
          selected: selected,
          icon: Icons.campaign_rounded,
          iconColor: GardenColors.potOrange,
          title: 'Todas',
          subtitle: 'Actualizaciones diarias de cada planta',
        ),
        const SizedBox(height: 12),
        _radioOptionRich(
          value: 'muted',
          selected: selected,
          icon: Icons.notifications_off_rounded,
          iconColor: GardenColors.inkSoft,
          title: 'Silenciado',
          subtitle: 'Puedes activarlas en ajustes cuando quieras',
        ),
        const SizedBox(height: 40),
        _primaryButton('A escucharlas 🌿', () {
          ref.read(authStateProvider.notifier).completeOnboarding();
          nav.changeTab(TabId.dashboard);
        }),
      ],
    );
  }

Widget _buildAppBasics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.menu_book_rounded, color: GardenColors.leafDark, size: 20),
              SizedBox(width: 8),
              Text(
                'Básicos de la App',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: GardenColors.ink,
                ),
              ),
            ],
          ),
        ),
        _InteractiveBasicItem(
          icon: GardenIcons.plantChat,
          iconBg: GardenColors.sageLight,
          iconColor: GardenColors.leafDark,
          title: 'El Traductor de Plantas',
          description: 'No más números aburridos. Tus plantas te dirán cómo se sienten a través de chismes ingeniosos en su propio canal de chat.',
        ),
        const SizedBox(height: 12),
        _InteractiveBasicItem(
          icon: GardenIcons.chat,
          iconBg: GardenColors.creamLight,
          iconColor: GardenColors.golden,
          title: 'Chat Botánico con IA',
          description: 'Pregúntale a nuestra IA botánica cualquier duda sobre plagas, abonos, poda o consejos personalizados para mantener tu jardín radiante.',
        ),
        const SizedBox(height: 12),
        _InteractiveBasicItem(
          icon: GardenIcons.friendPlants,
          iconBg: GardenColors.sageLight,
          iconColor: GardenColors.leafDark,
          title: 'Jardín de Amigos',
          description: 'Conéctate con otros entusiastas de las plantas. Visita sus jardines virtuales, presume tus especies y comparte logros botánicos.',
        ),
        const SizedBox(height: 12),
        _InteractiveBasicItem(
          icon: GardenIcons.calendarAlt,
          iconBg: GardenColors.creamPaper,
          iconColor: GardenColors.potOrange,
          title: 'Gráficos de Salud e Historial',
          description: 'Revisa de forma interactiva la evolución histórica de humedad, luz y temperatura para entender mejor los ciclos de tu planta.',
        ),
        const SizedBox(height: 12),
        _InteractiveBasicItem(
          icon: GardenIcons.notification,
          iconBg: GardenColors.creamLight,
          iconColor: GardenColors.heartRed,
          title: 'Alertas justo cuando importan',
          description: 'Recibe notificaciones automáticas y personalizadas únicamente cuando los sensores detecten que tu planta corre algún peligro.',
        ),
      ],
    );
  }


Widget _primaryButton(String text, VoidCallback? onTap) {
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? GardenColors.leafDark : GardenColors.dustLight,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: enabled ? 2 : 0,
          shadowColor: GardenColors.ink.withValues(alpha: 0.18),
        ),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: enabled ? Colors.white : GardenColors.inkSoft)),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    if (_step == OnboardingStep.identify) {
      return PlantIdentifyScreen(
        onBack: () => setState(() => _step = OnboardingStep.checklist),
        onCompleted: () => setState(() {
          _isPlantIdentified = true;
          _step = OnboardingStep.checklist;
        }),
      );
    }
    
    if (_step == OnboardingStep.sensor) {
      return SensorSetupView(
        onCancel: () => setState(() => _step = OnboardingStep.checklist),
        onComplete: () => setState(() {
          _isSensorConnected = true;
          _step = OnboardingStep.checklist;
        }),
      );
    }

    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      body: SafeArea(
        child: SingleChildScrollView(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Padding(
              key: ValueKey(_step),
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: switch (_step) {
                OnboardingStep.wow => _buildWowStep(),
                OnboardingStep.checklist => _buildChecklistStep(),
                OnboardingStep.config => _buildConfigStep(ref.read(navigationProvider.notifier)),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
        ),
      ),
    );
  }
}


class _InteractiveBasicItem extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;

  const _InteractiveBasicItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GardenColors.dustLight, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
            child: GardenIcon(asset: icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: GardenColors.ink)),
                const SizedBox(height: 6),
                Text(description, style: const TextStyle(fontSize: 13, color: GardenColors.inkSoft, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
