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
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            icon: const Icon(Icons.arrow_back_rounded, color: GardenColors.ink, size: 28),
            onPressed: () => setState(() => _step = OnboardingStep.wow),
          ),
        ),
        const SizedBox(height: 16),
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
          onTap: _showSensorModal,
          iconAsset: GardenIcons.logroSensores,
          color: GardenColors.potOrange,
        ),
        const SizedBox(height: 40),

        _ComicButton(
          text: 'Continuar',
          onTap: canContinue ? () => setState(() => _step = OnboardingStep.config) : null,
          color: GardenColors.heartRed,
        ),
      ],
    );
  }

  void _showSensorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: GardenColors.creamSolid,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: GardenColors.ink, width: 2.5),
              left: BorderSide(color: GardenColors.ink, width: 2.5),
              right: BorderSide(color: GardenColors.ink, width: 2.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: GardenColors.ink.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 32),
              const GardenIcon(asset: GardenIcons.logroSensores, size: 80),
              const SizedBox(height: 24),
              const Text(
                '¿Tienes el Sensor?',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: GardenColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'El sensor es esencial para monitorear la salud de tus plantas en tiempo real.',
                style: TextStyle(fontSize: 16, color: GardenColors.inkSoft),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _ComicButton(
                text: 'Sí, conectarlo ahora',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _step = OnboardingStep.sensor);
                },
                color: GardenColors.leafDark,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isSensorSkipped = true);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text(
                  'Aún no lo tengo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GardenColors.inkSoft),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
        image: DecorationImage(
          image: const AssetImage('images/PaperTexture.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.3),
            BlendMode.dstATop,
          ),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDone ? color : GardenColors.ink, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: isDone ? color : GardenColors.ink,
            blurRadius: 0,
            offset: const Offset(4, 6),
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
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: GardenColors.ink.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image.asset(
                'images/logo_no_text.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Hero Typography
        const Text(
          'Tus plantas tienen algo\nque decirte...',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.2,
              color: GardenColors.ink),
        ),
        const SizedBox(height: 32),
        
        // Scroll Indicator
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, -_floatAnimation.value * 0.5),
            child: child,
          ),
          child: const Column(
            children: [
              Text(
                'Desliza para descubrir',
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: GardenColors.potOrange,
                ),
              ),
              SizedBox(height: 8),
              Icon(Icons.keyboard_arrow_down_rounded, color: GardenColors.potOrange, size: 32),
            ],
          ),
        ),
        const SizedBox(height: 48),
        _buildAppBasics(),
        const SizedBox(height: 48),
        _primaryButton('¡Empecemos la aventura!', () {
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Text(
            'Básicos de la App',
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: GardenColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const _InteractiveBasicItem(
          icon: GardenIcons.basicPlantTranslator,
          iconBg: GardenColors.sageLight,
          title: 'El Traductor de Plantas',
          description: 'No más números aburridos. Tus plantas te dirán cómo se sienten a través de chismes ingeniosos en su propio canal de chat.',
          isLeftAligned: true,
        ),
        const SizedBox(height: 24),
        const _InteractiveBasicItem(
          icon: GardenIcons.basicBotanicalChat,
          iconBg: GardenColors.creamLight,
          title: 'Chat Botánico con IA',
          description: 'Pregúntale a nuestra IA botánica cualquier duda sobre plagas, abonos, poda o consejos personalizados para mantener tu jardín radiante.',
          isLeftAligned: false,
        ),
        const SizedBox(height: 24),
        const _InteractiveBasicItem(
          icon: GardenIcons.basicFriendsGarden,
          iconBg: GardenColors.sageLight,
          title: 'Jardín de Amigos',
          description: 'Conéctate con otros entusiastas de las plantas. Visita sus jardines virtuales, presume tus especies y comparte logros botánicos.',
          isLeftAligned: true,
        ),
        const SizedBox(height: 24),
        const _InteractiveBasicItem(
          icon: GardenIcons.basicHealthGraphics,
          iconBg: GardenColors.creamPaper,
          title: 'Gráficos e Historial',
          description: 'Revisa de forma interactiva la evolución histórica de humedad, luz y temperatura para entender mejor los ciclos de tu planta.',
          isLeftAligned: false,
        ),
        const SizedBox(height: 24),
        const _InteractiveBasicItem(
          icon: GardenIcons.basicAlerts,
          iconBg: GardenColors.creamLight,
          title: 'Alertas Inteligentes',
          description: 'Recibe notificaciones automáticas y personalizadas únicamente cuando los sensores detecten que tu planta corre algún peligro.',
          isLeftAligned: true,
        ),
      ],
    );
  }


Widget _primaryButton(String text, VoidCallback? onTap) {
    return _ComicButton(
      text: text,
      onTap: onTap,
      color: GardenColors.leafDark,
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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('images/PaperTexture.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withValues(alpha: 0.4),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: SafeArea(
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
      ),
    );
  }
}


class _InteractiveBasicItem extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String title;
  final String description;
  final bool isLeftAligned;

  const _InteractiveBasicItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.isLeftAligned,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GardenColors.ink, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Transform.scale(
          scale: 1.35, // Ampliamos ligeramente para recortar los márgenes de la imagen generada
          child: GardenIcon(
            asset: icon,
            size: 80,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );

    final textWidget = Expanded(
      child: Column(
        crossAxisAlignment: isLeftAligned ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            title, 
            textAlign: isLeftAligned ? TextAlign.left : TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 17, 
              fontWeight: FontWeight.w800, 
              color: GardenColors.ink
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description, 
            textAlign: isLeftAligned ? TextAlign.left : TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14, 
              color: GardenColors.inkSoft, 
              height: 1.4
            ),
          ),
        ],
      ),
    );

    final rowChildren = isLeftAligned 
        ? [iconWidget, const SizedBox(width: 16), textWidget]
        : [textWidget, const SizedBox(width: 16), iconWidget];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GardenColors.creamLight.withValues(alpha: 1.0),
        image: DecorationImage(
          image: const AssetImage('images/PaperTexture.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.3),
            BlendMode.dstATop,
          ),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GardenColors.ink, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: GardenColors.ink,
            blurRadius: 0,
            offset: const Offset(4, 6),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: rowChildren,
      ),
    );
  }
}

class _ComicButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color color;

  const _ComicButton({
    required this.text,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final actualColor = enabled ? color : GardenColors.dustLight;
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1 (Crayon offset 1)
            Positioned(
              left: 4, right: -2, top: 4, bottom: -2,
              child: Container(
                decoration: BoxDecoration(
                  color: actualColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: actualColor.withValues(alpha: 0.4), width: 2.5),
                ),
              ),
            ),
            // Layer 2 (Crayon offset 2)
            Positioned(
              left: -3, right: 3, top: -1, bottom: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: actualColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: actualColor.withValues(alpha: 0.6), width: 2.5),
                ),
              ),
            ),
            // Main Button
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: actualColor,
                  image: DecorationImage(
                    image: const AssetImage('images/PaperTexture.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.3),
                      BlendMode.dstATop,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: actualColor, width: 3.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: enabled ? Colors.white : GardenColors.inkSoft,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
