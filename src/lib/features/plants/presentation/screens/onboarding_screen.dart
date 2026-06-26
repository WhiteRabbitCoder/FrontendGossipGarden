import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gossip_garden/core/theme/garden_colors.dart';
import 'package:gossip_garden/core/theme/garden_icons.dart';
import 'package:gossip_garden/core/widgets/garden_icon.dart';
import 'package:gossip_garden/features/plants/presentation/providers/navigation_provider.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';
import 'package:gossip_garden/features/plants/presentation/screens/plant_identify_screen.dart';
import 'package:gossip_garden/features/plants/presentation/providers/achievement_providers.dart';
import 'package:gossip_garden/features/plants/presentation/providers/sensor_setup_providers.dart';

enum OnboardingStep { wow, choosePath, connect, identify, firstInsight, config }

final onboardingStepProvider =
    StateProvider<OnboardingStep>((ref) => OnboardingStep.wow);

final connectionStatusProvider = StateProvider<String>((ref) => 'idle');

final usesSensorProvider = StateProvider<bool>((ref) => true);

final notificationPreferenceProvider =
    StateProvider<String>((ref) => 'important');

// ── WiFi Setup providers ──────────────────────────────────────────────────────
final wifiSsidProvider = StateProvider<String>((ref) => '');
final wifiPasswordProvider = StateProvider<String>((ref) => '');
final wifiSetupPhaseProvider =
    StateProvider<_WifiPhase>((ref) => _WifiPhase.instruction);
final wifiNetworksProvider = StateProvider<List<WifiNetworkOption>>((ref) => []);
final wifiScanningProvider = StateProvider<bool>((ref) => false);
final wifiErrorProvider = StateProvider<String?>((ref) => null);
final sensorNetworksProvider = StateProvider<List<String>>((ref) => []);

enum _WifiPhase {
  instruction,
  verifying,
  scanning,
  form,
  connecting,
  connected,
  error
}



class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _staggerController;
  late Animation<double> _floatAnimation;
  // Animaciones escalonadas para los 3 íconos del paso wow
  late List<Animation<double>> _iconFadeAnims;
  late List<Animation<Offset>> _iconSlideAnims;

  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _showPasswordField = false;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Stagger: 3 íconos aparecen con 120ms de delay entre cada uno
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _iconFadeAnims = List.generate(3, (i) {
      final start = i * 0.25;
      final end = start + 0.55;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end.clamp(0, 1), curve: Curves.easeOut),
        ),
      );
    });

    _iconSlideAnims = List.generate(3, (i) {
      final start = i * 0.25;
      final end = start + 0.55;
      return Tween<Offset>(
        begin: const Offset(0, 0.4),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end.clamp(0, 1), curve: Curves.easeOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _staggerController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _skipToApp() {
    ref.read(authStateProvider.notifier).completeOnboarding();
    ref.read(navigationProvider.notifier).changeTab(TabId.dashboard);
  }

  void _goBack() {
    final step = ref.read(onboardingStepProvider);

    // Dentro del paso connect, manejar las sub-fases del WiFi antes de salir del paso
    if (step == OnboardingStep.connect) {
      final phase = ref.read(wifiSetupPhaseProvider);
      switch (phase) {
        case _WifiPhase.verifying:
        case _WifiPhase.error:
          ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.instruction;
          return;
        case _WifiPhase.scanning:
          ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.instruction;
          return;
        case _WifiPhase.form:
          ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.scanning;
          return;
        case _WifiPhase.connected:
          // Ya conectado — volver al paso anterior del onboarding
          break;
        case _WifiPhase.connecting:
          // No permitir volver mientras se está conectando
          return;
        case _WifiPhase.instruction:
          // Salir del paso connect hacia choosePath
          break;
      }
    }

    // Navegar al paso anterior en el flujo principal
    switch (step) {
      case OnboardingStep.wow:
        return; // Ya estamos al inicio
      case OnboardingStep.choosePath:
        ref.read(onboardingStepProvider.notifier).state = OnboardingStep.wow;
      case OnboardingStep.connect:
        ref.read(onboardingStepProvider.notifier).state = OnboardingStep.choosePath;
        _startPairing(); // Resetear estado WiFi
      case OnboardingStep.identify:
        // Si usa sensor, volver a connect; si no, volver a choosePath
        final usesSensor = ref.read(usesSensorProvider);
        ref.read(onboardingStepProvider.notifier).state =
            usesSensor ? OnboardingStep.connect : OnboardingStep.choosePath;
      case OnboardingStep.firstInsight:
        ref.read(onboardingStepProvider.notifier).state = OnboardingStep.identify;
      case OnboardingStep.config:
        ref.read(onboardingStepProvider.notifier).state = OnboardingStep.firstInsight;
    }
  }

  void _startWifiConnection() async {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text;
    if (ssid.isEmpty) return;

    ref.read(wifiErrorProvider.notifier).state = null;
    ref.read(wifiSsidProvider.notifier).state = ssid;
    ref.read(wifiPasswordProvider.notifier).state = password;
    ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.connecting;

    try {
      final client = ref.read(esp32ApiClientProvider);
      final success = await client.connectWifi(ssid, password);
      
      if (!mounted) return;

      if (success) {
        ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.connected;
        ref.read(achievementStatsProvider.notifier).recordSensorSetup();
      } else {
        ref.read(wifiErrorProvider.notifier).state = 'Contraseña incorrecta o red fuera de alcance.';
        ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.error;
      }
    } catch (e) {
      if (!mounted) return;
      ref.read(wifiErrorProvider.notifier).state = e.toString().replaceAll('Exception: ', '');
      ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.error;
    }
  }

  void _showWifiForm() {
    ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.form;
  }

  void _startPairing() {
    ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.instruction;
    ref.read(wifiNetworksProvider.notifier).state = [];
    ref.read(wifiScanningProvider.notifier).state = false;
    ref.read(wifiErrorProvider.notifier).state = null;
    ref.read(wifiSsidProvider.notifier).state = '';
    ref.read(wifiPasswordProvider.notifier).state = '';
    _ssidController.clear();
    _passwordController.clear();
    setState(() {
      _passwordVisible = false;
      _showPasswordField = false;
    });
  }

  void _verifyAndStartScanning() async {
    if (!mounted) return;
    
    // Entramos en modo carga real
    ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.verifying;
    ref.read(wifiErrorProvider.notifier).state = null;
    
    try {
      final client = ref.read(esp32ApiClientProvider);
      final networks = await client.getWifiNetworks();
      final macAddress = await client.getSystemInfo();
      
      if (!mounted) return;
      
      // Guardamos las redes pre-cargadas y la MAC
      ref.read(wifiNetworksProvider.notifier).state = networks;
      ref.read(sensorMacAddressProvider.notifier).state = macAddress;
      
      // Ahora SÍ avanzamos a la pantalla de éxito (Chip en línea)
      ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.scanning;
    } catch (e) {
      if (!mounted) return;
      ref.read(wifiErrorProvider.notifier).state = e.toString().replaceAll('Exception: ', '');
      ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.error;
    }
  }

  void _scanNetworks() async {
    ref.read(wifiErrorProvider.notifier).state = null;
    ref.read(wifiScanningProvider.notifier).state = true;
    
    try {
      final client = ref.read(esp32ApiClientProvider);
      final networks = await client.getWifiNetworks();
      
      if (!mounted) return;
      ref.read(wifiNetworksProvider.notifier).state = networks;
      // Si todo va bien en el refresh manual, nos mantenemos en la vista del form.
    } catch (e) {
      if (!mounted) return;
      ref.read(wifiErrorProvider.notifier).state = e.toString().replaceAll('Exception: ', '');
      ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.error;
    } finally {
      if (mounted) {
        ref.read(wifiScanningProvider.notifier).state = false;
      }
    }
  }

  void _selectNetwork(WifiNetworkOption net) {
    _ssidController.text = net.ssid;
    _passwordController.clear();
    _passwordVisible = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: GardenColors.creamPaper,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      net.ssid.isEmpty ? 'Conectar a red oculta' : 'Conectar a ${net.ssid}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: GardenColors.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (net.ssid.isEmpty) ...[
                      _wifiTextField(
                        controller: _ssidController,
                        label: 'Nombre de la red (SSID)',
                        hint: 'Escribe el nombre de la red',
                        iconAsset: GardenIcons.wifi,
                        obscure: false,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _wifiTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      hint: '••••••••',
                      iconAsset: GardenIcons.lock,
                      obscure: !_passwordVisible,
                      suffixIcon: IconButton(
                        icon: GardenIcon(
                          asset: _passwordVisible
                              ? GardenIcons.eyeClose
                              : GardenIcons.eyeOpen,
                          size: 20,
                          opacity: 0.6,
                        ),
                        onPressed: () => setModalState(
                            () => _passwordVisible = !_passwordVisible),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: _primaryButton(
                        'Conectar al sensor',
                        () {
                          Navigator.pop(context);
                          _startWifiConnection();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(onboardingStepProvider);
    final wifiPhase = ref.watch(wifiSetupPhaseProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    final isFirstStep = step == OnboardingStep.wow;
    final isLastStep = step == OnboardingStep.config;

    // Ocultar back si estamos conectando (operación en curso)
    final isConnecting = step == OnboardingStep.connect &&
        wifiPhase == _WifiPhase.connecting;

    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Padding(
                key: ValueKey(step),
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                child: step == OnboardingStep.identify
                    // Paso identify: deja que PlantIdentifyScreen haga su propio scroll
                    ? Column(
                        children: [
                          Expanded(
                            child: _buildStepContent(step, navNotifier),
                          ),
                          const SizedBox(height: 16),
                          _buildProgress(step),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: _buildStepContent(step, navNotifier),
                          ),
                          const SizedBox(height: 16),
                          _buildProgress(step),
                        ],
                      ),
              ),
            ),

            // ── Botón Regresar ───────────────────────────────────────────
            if (!isFirstStep && !isConnecting)
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  onPressed: _goBack,
                  style: IconButton.styleFrom(
                    foregroundColor: GardenColors.inkSoft,
                    backgroundColor: Colors.white.withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(10),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  tooltip: 'Regresar',
                ),
              ),

            // ── Botón Skip ──────────────────────────────────────────────
            if (!isFirstStep && !isLastStep)
              Positioned(
                top: 8,
                right: 8,
                child: TextButton(
                  onPressed: _skipToApp,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black45,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Saltar',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 13),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(OnboardingStep step) {
    final index = OnboardingStep.values.indexOf(step);
    final total = OnboardingStep.values.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            total,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 32 : 10,
              height: 10,
              decoration: BoxDecoration(
                color:
                    i <= index ? GardenColors.leafDark : GardenColors.dustLight,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Paso ${index + 1} de $total',
          style: const TextStyle(
            fontSize: 11,
            color: GardenColors.inkSoft,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(
      OnboardingStep step, NavigationNotifier navNotifier) {
    switch (step) {
      case OnboardingStep.wow:
        return _buildScrollableStep(_buildWowStep());
      case OnboardingStep.choosePath:
        return _buildChoosePathStep();
      case OnboardingStep.connect:
        return _buildScrollableStep(_buildWifiSetupStep());
      case OnboardingStep.identify:
        return _buildIdentifyStep();
      case OnboardingStep.firstInsight:
        return _buildScrollableStep(_buildFirstInsightStep());
      case OnboardingStep.config:
        return _buildScrollableStep(_buildConfigStep(navNotifier));
    }
  }

  Widget _buildScrollableStep(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }

  // ── Paso 1: Wow ─────────────────────────────────────────────────────────

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
        const SizedBox(height: 48),
        _primaryButton('Quiero escucharlas', () {
          // Reiniciar stagger para verlo de nuevo si el usuario regresa
          _staggerController
            ..reset()
            ..forward();
          ref.read(onboardingStepProvider.notifier).state =
              OnboardingStep.choosePath;
        }),
      ],
    );
  }



  // ── Paso 2b: Elegir ruta (con o sin sensor) ────────────────────────────

  Widget _buildChoosePathStep() {
    final usesSensor = ref.watch(usesSensorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Logo + brand ────────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: GardenColors.leafDark,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('images/logo_no_text.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Gossip Garden',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: GardenColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Título ──────────────────────────────────────────────────────
        const Text(
          'Tu jardín te espera',
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: GardenColors.ink,
              height: 1.1),
        ),
        const SizedBox(height: 6),
        Text(
          'Elige cómo quieres comenzar',
          style: TextStyle(fontSize: 14, color: GardenColors.inkSoft),
        ),
        const SizedBox(height: 10),
        Container(
          width: 56,
          height: 3,
          decoration: BoxDecoration(
            color: GardenColors.leafDark,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 24),

        // ── Toggle Con sensor / Sin sensor ──────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: GardenColors.dustLight,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _sensorToggleOption('Con sensor', GardenIcons.wifi, true, usesSensor),
              _sensorToggleOption('Sin sensor', GardenIcons.plantEco, false, usesSensor),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Stepper ─────────────────────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: usesSensor
                ? _buildSensorStepper()
                : _buildNoSensorStepper(),
          ),
        ),

        const SizedBox(height: 16),

        // ── CTA ─────────────────────────────────────────────────────────
        _primaryButton('Siguiente paso  →', () {
          if (usesSensor) {
            ref.read(onboardingStepProvider.notifier).state =
                OnboardingStep.connect;
            _startPairing();
          } else {
            ref.read(onboardingStepProvider.notifier).state =
                OnboardingStep.identify;
          }
        }),
      ],
    );
  }

  Widget _sensorToggleOption(
      String label, String iconAsset, bool isSensor, bool usesSensor) {
    final isSelected = isSensor == usesSensor;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            ref.read(usesSensorProvider.notifier).state = isSensor,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? GardenColors.leafDark : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: GardenColors.leafDark.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GardenIcon(
                asset: iconAsset,
                size: 16,
                opacity: isSelected ? 1.0 : 0.6,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : GardenColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorStepper() {
    return Column(
      key: const ValueKey('sensor'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepperItem(
          number: 1,
          title: 'Crear cuenta',
          isDone: true,
          isLast: false,
        ),
        _stepperItem(
          number: 2,
          title: 'Conectar a la red del sensor',
          description:
              'Sal de la app y ve a los ajustes de tu celular. Conéctate a la red WiFi del sensor.',
          isActive: true,
          isLast: false,
          actionWidget: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: GardenColors.sageLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GardenColors.sage, width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GardenIcon(asset: GardenIcons.wifi, size: 14),
                SizedBox(width: 7),
                Text(
                  'gossip_garden',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: GardenColors.leafDark,
                      letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
        _stepperItem(
          number: 3,
          title: 'Volver a tu red local',
          isLast: false,
        ),
        _stepperItem(
          number: 4,
          title: 'Agregar tu planta',
          isLast: false,
        ),
        _stepperItem(
          number: 5,
          title: '¡Listo para tu jardín!',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildNoSensorStepper() {
    return Column(
      key: const ValueKey('nosensor'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepperItem(
          number: 1,
          title: 'Crear cuenta',
          isDone: true,
          isLast: false,
        ),
        _stepperItem(
          number: 2,
          title: 'Agregar tu planta',
          description:
              'Búscala por nombre o identificala con IA. Puedes conectar un sensor más adelante.',
          isActive: true,
          isLast: false,
          actionWidget: Row(
            children: [
              // Buscar nombre — disponible
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(onboardingStepProvider.notifier).state =
                        OnboardingStep.identify;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: GardenColors.sageLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: GardenColors.leafDark.withValues(alpha: 0.3),
                          width: 1),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_rounded,
                            size: 20, color: GardenColors.leafDark),
                        SizedBox(height: 4),
                        Text(
                          'Buscar nombre',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: GardenColors.leafDark),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Reconocer con IA — próximamente
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: GardenColors.creamLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: GardenColors.dustLight, width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                GardenColors.potOrange,
                                GardenColors.leafGreen,
                              ],
                            ).createShader(bounds),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reconocer con IA',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: GardenColors.inkSoft),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Badge próximamente
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              GardenColors.potOrange,
                              Color(0xFFE8825C),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: GardenColors.potOrange.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Text(
                          'Próximo',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _stepperItem(
          number: 3,
          title: '¡Listo para tu jardín!',
          isLast: true,
        ),
      ],
    );
  }

  Widget _stepperItem({
    required int number,
    required String title,
    String? description,
    bool isDone = false,
    bool isActive = false,
    bool isLast = false,
    Widget? actionWidget,
  }) {
    final Color circleColor = isDone
        ? GardenColors.leafGreen
        : isActive
            ? GardenColors.leafDark
            : GardenColors.dustLight;

    final Widget circleContent = isDone
        ? const GardenIcon(asset: GardenIcons.logroDesbloqueado, size: 15)
        : Text(
            '$number',
            style: TextStyle(
              color: isActive ? Colors.white : GardenColors.inkSoft,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          );

    final double lineHeight = isActive ? 110.0 : 36.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Círculo + línea ─────────────────────────────────────────────
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: GardenColors.leafDark.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Center(child: circleContent),
            ),
            if (!isLast)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 2,
                height: lineHeight,
                decoration: BoxDecoration(
                  color: isDone
                      ? GardenColors.leafGreen.withValues(alpha: 0.5)
                      : GardenColors.sage.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        // ── Contenido ────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isActive ? 16 : 14,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isDone
                        ? GardenColors.inkSoft
                        : isActive
                            ? GardenColors.ink
                            : GardenColors.inkSoft,
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                    decorationColor: GardenColors.inkSoft,
                  ),
                ),
                if (isActive && description != null) ...
                [
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                        fontSize: 13,
                        color: GardenColors.inkSoft,
                        height: 1.45),
                  ),
                ],
                if (actionWidget != null) ...
                [
                  const SizedBox(height: 10),
                  actionWidget,
                ],
                if (!isLast) const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Paso 3: WiFi Setup IoT ──────────────────────────────────────────────

  Widget _buildWifiSetupStep() {
    final phase = ref.watch(wifiSetupPhaseProvider);

    return switch (phase) {
      _WifiPhase.instruction => _buildWifiInstruction(),
      _WifiPhase.verifying => _buildWifiVerifying(),
      _WifiPhase.scanning => _buildWifiScanning(),
      _WifiPhase.form => _buildWifiForm(),
      _WifiPhase.connecting => _buildWifiConnecting(),
      _WifiPhase.connected => _buildWifiConnected(),
      _WifiPhase.error => _buildWifiError(),
    };
  }

  Widget _buildWifiForm() {
    final networks = ref.watch(wifiNetworksProvider);
    final scanning = ref.watch(wifiScanningProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GardenColors.leafDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const GardenIcon(
                    asset: GardenIcons.logroSensores, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Conecta tus sensores',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: GardenColors.ink)),
                    Text('Elige tu red WiFi para configurar el dispositivo IoT',
                        style: TextStyle(
                            fontSize: 12, color: GardenColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Sección redes disponibles ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Redes disponibles',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: GardenColors.inkSoft,
                      letterSpacing: 0.5)),
              TextButton.icon(
                onPressed: scanning ? null : _scanNetworks,
                icon: scanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                GardenColors.leafDark)),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(scanning ? 'Buscando...' : 'Buscar'),
                style: TextButton.styleFrom(
                    foregroundColor: GardenColors.leafDark,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Lista de redes
          if (networks.isEmpty && !scanning)
            GestureDetector(
              onTap: _scanNetworks,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: GardenColors.dustLight, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: GardenColors.ink.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GardenIcon(
                        asset: GardenIcons.wifiConnect,
                        size: 40,
                        opacity: 0.6),
                    const SizedBox(height: 10),
                    Text('Toca para buscar redes',
                        style: TextStyle(
                            color: GardenColors.inkSoft, fontSize: 13)),
                  ],
                ),
              ),
            )
          else if (scanning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: GardenColors.leafDark.withValues(alpha: 0.3), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: GardenColors.ink.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(GardenColors.leafDark)),
                  const SizedBox(height: 14),
                  Text('Buscando redes cercanas...',
                      style:
                          TextStyle(color: GardenColors.inkSoft, fontSize: 13)),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: GardenColors.dustLight, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: GardenColors.ink.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                children: networks.asMap().entries.map((e) {
                  final i = e.key;
                  final net = e.value;
                  final isLast = i == networks.length - 1;
                  final isSelected = _ssidController.text == net.ssid;
                  return _buildNetworkTile(net, isLast, isSelected);
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: scanning
                ? null
                : () {
                    _selectNetwork(const WifiNetworkOption(
                        ssid: 'Ingresar red oculta',
                        signal: 0,
                        secured: true));
                  },
            icon: const GardenIcon(asset: GardenIcons.addPlant, size: 18),
            label: const Text('Conectarse a red oculta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: GardenColors.leafDark,
              side: const BorderSide(color: GardenColors.leafDark),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNetworkTile(WifiNetworkOption net, bool isLast, bool isSelected) {
    final signalIcon = [
      Icons.network_wifi_1_bar,
      Icons.network_wifi_2_bar,
      Icons.network_wifi_3_bar,
      Icons.signal_wifi_4_bar,
    ][net.signal.clamp(1, 4) - 1];

    final signalColor =
        net.signal >= 3 ? GardenColors.leafDark : GardenColors.potOrange;

    return GestureDetector(
      onTap: () => _selectNetwork(net),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? GardenColors.leafDark.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isSelected ? 18 : 0),
            bottom: Radius.circular(isSelected ? 18 : 0),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Icon(signalIcon, color: signalColor, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(net.ssid,
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14)),
                        Text(
                          net.secured ? 'Protegida' : 'Abierta',
                          style: TextStyle(
                              fontSize: 11,
                              color: net.secured
                                  ? GardenColors.inkSoft
                                  : GardenColors.potOrange),
                        ),
                      ],
                    ),
                  ),
                  if (net.secured)
                    Icon(Icons.lock_rounded,
                        size: 16, color: GardenColors.inkSoft),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.check_circle_rounded,
                          size: 20, color: GardenColors.leafDark),
                    ),
                ],
              ),
            ),
            if (!isLast)
              Divider(height: 1, indent: 52, color: GardenColors.dustLight),
          ],
        ),
      ),
    );
  }

  Widget _wifiTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String iconAsset,
    required bool obscure,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: GardenIcon(asset: iconAsset, size: 20),
        ),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(color: GardenColors.leafDark),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: GardenColors.dustLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: GardenColors.dustLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: GardenColors.leafDark, width: 2),
        ),
      ),
    );
  }

  Widget _buildWifiInstruction() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const GardenIcon(asset: GardenIcons.wifiConnect, size: 64),
        const SizedBox(height: 24),
        const Text(
          'Configuración del chip',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _card(
          child: const Column(
            children: [
              Text(
                'Conectate a la red wifi del sensor en los ajustes del dispositivo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 12),
              Text(
                'gossip_garden',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: GardenColors.leafDark,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _primaryButton('Verificar conexión', _verifyAndStartScanning),
      ],
    );
  }

  Widget _buildWifiVerifying() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: GardenColors.leafDark),
          const SizedBox(height: 32),
          const Text(
            'Sincronizando con el chip...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('Estamos recibiendo informacion, espere un momento'),
        ],
      ),
    );
  }

  Widget _buildWifiScanning() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GardenColors.leafDark.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.wifi_find_rounded,
                size: 64, color: GardenColors.leafDark),
          ),
          const SizedBox(height: 32),
          const Text(
            'Chip en linea',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: GardenColors.leafDark),
          ),
          const SizedBox(height: 12),
          Text(
            'Conecta tu dispositivo a redes wifi disponibles en tu entorno para continuar',
            textAlign: TextAlign.center,
            style: TextStyle(color: GardenColors.inkSoft, height: 1.5),
          ),
          const SizedBox(height: 48),
          _primaryButton('Ver redes disponibles', _showWifiForm),
        ],
      ),
    );
  }

  Widget _buildWifiConnecting() {
    final ssid = ref.watch(wifiSsidProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animación de ondas WiFi
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GardenColors.potOrange.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.cloud_upload_rounded,
                  size: 64, color: GardenColors.potOrange),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Configurando chip...',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Enviando credenciales de "$ssid" al chip.\nEl chip intentará conectarse a internet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GardenColors.inkSoft, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiConnected() {
    final ssid = ref.watch(wifiSsidProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GardenColors.leafGreen.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                size: 64, color: GardenColors.leafGreen),
          ),
          const SizedBox(height: 32),
          const Text(
            '¡Conexión exitosa!',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: GardenColors.leafGreen),
          ),
          const SizedBox(height: 12),
          Text(
            'El chip se conectó a "$ssid"\ny ya está enviando datos de los sensores.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GardenColors.inkSoft, height: 1.5),
          ),
          const SizedBox(height: 48),
          _primaryButton('¡Mi planta está lista!', () {
            ref.read(onboardingStepProvider.notifier).state =
                OnboardingStep.identify;
          }),
        ],
      ),
    );
  }

  Widget _buildWifiError() {
    final errorMessage = ref.watch(wifiErrorProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GardenColors.heartRed.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.error_outline_rounded,
                size: 64, color: GardenColors.heartRed),
          ),
          const SizedBox(height: 32),
          const Text(
            'Error de configuración',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: GardenColors.heartRed),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'El chip no pudo conectarse a la red WiFi.\nVerifica la contraseña e intenta de nuevo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GardenColors.inkSoft, height: 1.5),
          ),
          const SizedBox(height: 48),
          _primaryButton('Reintentar', () {
            ref.read(wifiSetupPhaseProvider.notifier).state =
                _WifiPhase.instruction;
            _startPairing();
          }),
        ],
      ),
    );
  }

  // ── Paso 4: Identificar planta ──────────────────────────────────────────

  Widget _buildIdentifyStep() {
    return PlantIdentifyScreen(
      onCompleted: () {
        ref.read(onboardingStepProvider.notifier).state =
            OnboardingStep.firstInsight;
      },
    );
  }

  // ── Paso 5: Primer insight ──────────────────────────────────────────────

  Widget _buildFirstInsightStep() {
    final session = ref.watch(authStateProvider).value;
    final userName = session?.profile?.displayName?.split(' ').first ?? 'tú';

    return _FirstInsightTutorialWidget(
      userName: userName,
      onContinue: () {
        ref.read(onboardingStepProvider.notifier).state =
            OnboardingStep.config;
      },
    );
  }


  // ── Paso 6: Configuración notificaciones ────────────────────────────────

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

  // ── Widgets helpers ─────────────────────────────────────────────────────


  Widget _radioOptionRich({
    required String value,
    required String selected,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () =>
          ref.read(notificationPreferenceProvider.notifier).state = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? GardenColors.sageLight
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? GardenColors.leafDark.withValues(alpha: 0.5)
                : GardenColors.dustLight,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: GardenColors.ink.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? GardenColors.ink
                          : GardenColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: GardenColors.inkSoft),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected
                  ? GardenColors.leafDark
                  : GardenColors.dustLight,
              size: 22,
            ),
          ],
        ),
      ),
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GardenColors.dustLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: GardenColors.ink.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: child,
    );
  }
}

// ── Widget de Tutorial del Primer Insight (Paso 5) ──────────────────────────

class _FirstInsightTutorialWidget extends ConsumerStatefulWidget {
  final String userName;
  final VoidCallback onContinue;

  const _FirstInsightTutorialWidget({
    required this.userName,
    required this.onContinue,
  });

  @override
  ConsumerState<_FirstInsightTutorialWidget> createState() =>
      _FirstInsightTutorialWidgetState();
}

class _FirstInsightTutorialWidgetState
    extends ConsumerState<_FirstInsightTutorialWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Widget _buildSensorCard({
    required String label,
    required String value,
    required String iconAsset,
    required Color themeColor,
    required String gossipText,
    required String tipTitle,
    required String tipText,
    required IconData tipIcon,
    required double progressPercent,
  }) {
    // Escoger la animación correspondiente según el tipo de sensor
    Widget iconWidget = GardenIcon(
      asset: iconAsset,
      size: 22,
      color: themeColor,
    );

    if (iconAsset == GardenIcons.sun) {
      iconWidget = _SpinningIcon(child: iconWidget);
    } else if (iconAsset == GardenIcons.water) {
      iconWidget = _BouncingIcon(child: iconWidget);
    } else if (iconAsset == GardenIcons.thermostat) {
      iconWidget = _PulsingIcon(child: iconWidget);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            themeColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeColor.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: GardenColors.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: iconWidget),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: GardenColors.ink,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                value,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: themeColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _LivePulseBadge(color: themeColor),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 8,
                          width: double.infinity,
                          color: themeColor.withValues(alpha: 0.1),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: progressPercent),
                            duration: const Duration(milliseconds: 1400),
                            curve: Curves.easeOutBack,
                            builder: (context, val, _) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: val,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        themeColor.withValues(alpha: 0.5),
                                        themeColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeColor.withValues(alpha: 0.4),
                                        blurRadius: 4,
                                        spreadRadius: 0.5,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Gossip section styled as a Speech Bubble
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: CustomPaint(
                    size: const Size(12, 6),
                    painter: _BubbleTailPainter(color: GardenColors.creamLight),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: GardenColors.creamLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.zero,
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: GardenColors.dustLight,
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chisme en vivo 💬',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _TypewriterText(
                        text: gossipText,
                        duration: const Duration(milliseconds: 800),
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: GardenColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(tipIcon, size: 18, color: themeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: GardenColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tipText,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: GardenColors.inkSoft,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: _FloatingLeavesBackground(),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Logo y Título (Staggered 1)
            _AnimatedEntrance(
              controller: _entranceController,
              interval: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
              child: Column(
                children: [
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.04),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: GardenColors.sageLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: GardenColors.leafDark.withValues(alpha: 0.1),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'images/logo_no_text.png',
                            width: 46,
                            height: 46,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: GardenColors.ink,
                          height: 1.3),
                      children: [
                        const TextSpan(text: '¡Hola '),
                        TextSpan(
                          text: widget.userName,
                          style: const TextStyle(color: GardenColors.leafDark),
                        ),
                        const TextSpan(text: '! Tu planta tiene algo que decirte 🌵'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Desliza hacia abajo para conocer cómo interactúan los sensores y los básicos del cuidado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: GardenColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Card 1: Humedad (Staggered 2)
            _AnimatedEntrance(
              controller: _entranceController,
              interval: const Interval(0.25, 0.55, curve: Curves.easeOutCubic),
              child: _BouncingCard(
                onTap: () {},
                child: _buildSensorCard(
                  label: 'Humedad del suelo',
                  value: '31%',
                  iconAsset: GardenIcons.water,
                  themeColor: GardenColors.waterBlue,
                  gossipText: 'Mi tierra está al 31% — exactamente como me gusta. No me eches agua todavía, espera 3 días más.',
                  tipTitle: '¿Cómo funciona la Humedad?',
                  tipText: 'El sensor mide el agua en la raíz. Las suculentas y cactus odian el exceso de agua; riega solo cuando el chisme te lo pida.',
                  tipIcon: Icons.water_drop_outlined,
                  progressPercent: 0.31,
                ),
              ),
            ),
            
            // Card 2: Temperatura (Staggered 3)
            _AnimatedEntrance(
              controller: _entranceController,
              interval: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
              child: _BouncingCard(
                onTap: () {},
                child: _buildSensorCard(
                  label: 'Temperatura',
                  value: '22°C',
                  iconAsset: GardenIcons.thermostat,
                  themeColor: GardenColors.potOrange,
                  gossipText: 'Hace unos templados 22°C aquí. ¡Clima ideal para mis espinas! Mantenme lejos de corrientes de viento frío.',
                  tipTitle: '¿Cómo funciona la Temperatura?',
                  tipText: 'Las temperaturas extremas estresan la planta. Te notificaremos si el ambiente baja de 12°C o supera los 35°C.',
                  tipIcon: Icons.thermostat_rounded,
                  progressPercent: 0.55,
                ),
              ),
            ),
            
            // Card 3: Luz (Staggered 4)
            _AnimatedEntrance(
              controller: _entranceController,
              interval: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
              child: _BouncingCard(
                onTap: () {},
                child: _buildSensorCard(
                  label: 'Luz ambiente',
                  value: 'Alta',
                  iconAsset: GardenIcons.sun,
                  themeColor: GardenColors.golden,
                  gossipText: 'La luz solar es Alta. ¡Perfecto para hacer mi fotosíntesis y crecer con fuerza en esta maceta!',
                  tipTitle: '¿Cómo funciona la Luz?',
                  tipText: 'Mide la radiación solar. Los cactus necesitan luz Alta directa, mientras que las plantas tropicales prefieren luz indirecta.',
                  tipIcon: Icons.wb_sunny_outlined,
                  progressPercent: 0.85,
                ),
              ),
            ),

            const SizedBox(height: 16),
            
            // Bouncing down indicator (Staggered 5)
            _AnimatedEntrance(
              controller: _entranceController,
              interval: const Interval(0.55, 0.8, curve: Curves.easeOutCubic),
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.5 + (_pulseController.value * 0.5),
                      child: child,
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: 16,
                        color: GardenColors.leafDark,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Desliza para ver más básicos de la app',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: GardenColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Básicos Section (Staggered 6)
            _AnimatedEntrance(
              controller: _entranceController,
              interval: const Interval(0.65, 0.95, curve: Curves.easeOutCubic),
              child: _buildAppBasics(),
            ),
            const SizedBox(height: 32),
            
            // Continuar Button (Staggered 7)
            _AnimatedEntrance(
              controller: _entranceController,
              interval: const Interval(0.85, 1.0, curve: Curves.easeOutCubic),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GardenColors.leafDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 2,
                    shadowColor: GardenColors.ink.withValues(alpha: 0.18),
                  ),
                  child: const Text('Continuar',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── WIDGETS ANIMADOS COMPLEMENTARIOS ──────────────────────────────────────────

/// Animación de entrada staggered (desvanecimiento y deslizamiento hacia arriba).
class _AnimatedEntrance extends StatelessWidget {
  final AnimationController controller;
  final Interval interval;
  final Widget child;

  const _AnimatedEntrance({
    required this.controller,
    required this.interval,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final animValue = CurvedAnimation(
          parent: controller,
          curve: interval,
        ).value;

        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 32 * (1.0 - animValue)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Efecto táctil de rebote (escala hacia abajo al presionar y vuelve a su tamaño normal).
class _BouncingCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _BouncingCard({required this.child, this.onTap});

  @override
  State<_BouncingCard> createState() => _BouncingCardState();
}

class _BouncingCardState extends State<_BouncingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _controller,
        child: widget.child,
      ),
    );
  }
}

/// Icono giratorio continuo (para el sol de radiación).
class _SpinningIcon extends StatefulWidget {
  final Widget child;
  const _SpinningIcon({required this.child});

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: widget.child,
    );
  }
}

/// Icono flotante (arriba y abajo continuamente, para la gota de agua de la humedad).
class _BouncingIcon extends StatefulWidget {
  final Widget child;
  const _BouncingIcon({required this.child});

  @override
  State<_BouncingIcon> createState() => _BouncingIconState();
}

class _BouncingIconState extends State<_BouncingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -0.06),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// Icono de pulso en escala (para el termómetro).
class _PulsingIcon extends StatefulWidget {
  final Widget child;
  const _PulsingIcon({required this.child});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.94, end: 1.06).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

// ── WIDGETS ANIMADOS ADICIONALES ─────────────────────────────────────────────

/// Pintor para dibujar la cola de diálogo de la burbuja de chat.
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  const _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Indicador circular parpadeante "En vivo".
class _LivePulseBadge extends StatefulWidget {
  final Color color;
  const _LivePulseBadge({required this.color});

  @override
  State<_LivePulseBadge> createState() => _LivePulseBadgeState();
}

class _LivePulseBadgeState extends State<_LivePulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5 * _controller.value),
                    blurRadius: 6,
                    spreadRadius: 3 * _controller.value,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 5),
        Text(
          'En vivo',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: GardenColors.inkSoft.withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Revelación del texto de chisme progresivamente estilo máquina de escribir.
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const _TypewriterText({
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _characterCount = StepTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    // Demora un poco el inicio para que combine con el staggered fade-in de las cards
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(_TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.reset();
      _characterCount = StepTween(begin: 0, end: widget.text.length).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      );
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        final textToShow = widget.text.substring(0, _characterCount.value);
        return Text(
          textToShow,
          style: widget.style,
        );
      },
    );
  }
}

/// Ítem básico interactivo con efecto de escala al tacto y rotación del icono.
class _InteractiveBasicItem extends StatefulWidget {
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
  State<_InteractiveBasicItem> createState() => _InteractiveBasicItemState();
}

class _InteractiveBasicItemState extends State<_InteractiveBasicItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _iconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!_controller.isAnimating) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    widget.iconBg.withValues(alpha: 0.18),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _controller.isAnimating
                      ? widget.iconColor.withValues(alpha: 0.5)
                      : widget.iconColor.withValues(alpha: 0.14),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _controller.isAnimating
                        ? widget.iconColor.withValues(alpha: 0.15)
                        : widget.iconColor.withValues(alpha: 0.03),
                    blurRadius: _controller.isAnimating ? 14 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: _iconAnimation.value * 0.15 * 3.14159,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.iconBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.iconColor.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: GardenIcon(
                          asset: widget.icon,
                          size: 22,
                          color: widget.iconColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: GardenColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: GardenColors.inkSoft,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: widget.iconColor.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── FONDO DE HOJAS FLOTANTES ─────────────────────────────────────────────────

class _LeafParticle {
  double x;
  double y;
  double speed;
  double size;
  double rotation;
  double rotationSpeed;

  _LeafParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _FloatingLeavesBackground extends StatefulWidget {
  const _FloatingLeavesBackground();

  @override
  State<_FloatingLeavesBackground> createState() => _FloatingLeavesBackgroundState();
}

class _FloatingLeavesBackgroundState extends State<_FloatingLeavesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_LeafParticle> _particles = [];
  final int _particleCount = 6;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Distribuir partículas a lo largo del espacio de pantalla
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_LeafParticle(
        x: (i * 0.18 + 0.1),
        y: (0.1 + i * 0.15),
        speed: 0.02 + (i % 3) * 0.015,
        size: 8.0 + (i % 4) * 4.0,
        rotation: (i * 45) * 3.14159 / 180,
        rotationSpeed: 0.1 + (i % 2) * 0.2,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateParticles() {
    for (var p in _particles) {
      p.y += p.speed * 0.01;
      p.rotation += p.rotationSpeed * 0.01;
      p.x += 0.002 * (p.speed > 0.03 ? 1 : -1);

      if (p.y > 1.1) {
        p.y = -0.1;
        p.x = 0.1 + (DateTime.now().microsecond % 80) / 100.0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        _updateParticles();
        return CustomPaint(
          painter: _LeavesPainter(particles: _particles),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _LeavesPainter extends CustomPainter {
  final List<_LeafParticle> particles;
  const _LeavesPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GardenColors.sage.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    for (var p in particles) {
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);

      final path = Path();
      path.moveTo(0, -p.size);
      path.quadraticBezierTo(p.size * 0.6, 0, 0, p.size);
      path.quadraticBezierTo(-p.size * 0.6, 0, 0, -p.size);
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

