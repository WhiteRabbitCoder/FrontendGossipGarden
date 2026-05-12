import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gossip_garden/features/plants/presentation/providers/navigation_provider.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';
import 'package:gossip_garden/features/plants/presentation/providers/plant_providers.dart';
import 'package:gossip_garden/features/plants/presentation/screens/plant_identify_screen.dart';

enum OnboardingStep { wow, welcome, connect, identify, firstInsight, config }

final onboardingStepProvider =
    StateProvider<OnboardingStep>((ref) => OnboardingStep.wow);

final connectionStatusProvider = StateProvider<String>((ref) => 'idle');

final notificationPreferenceProvider =
    StateProvider<String>((ref) => 'important');

// ── WiFi Setup providers ──────────────────────────────────────────────────────
final wifiSsidProvider = StateProvider<String>((ref) => '');
final wifiPasswordProvider = StateProvider<String>((ref) => '');
final wifiSetupPhaseProvider = StateProvider<_WifiPhase>((ref) => _WifiPhase.instruction);
final wifiNetworksProvider = StateProvider<List<_WifiNetwork>>((ref) => []);
final wifiScanningProvider = StateProvider<bool>((ref) => false);
final sensorNetworksProvider = StateProvider<List<String>>((ref) => []);

enum _WifiPhase { instruction, verifying, scanning, form, connecting, connected, error }

class _WifiNetwork {
  final String ssid;
  final int signal; // 1-4 bars
  final bool secured;
  const _WifiNetwork({required this.ssid, required this.signal, required this.secured});
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _iconController;
  late Animation<double> _floatAnimation;
  late Animation<double> _iconAnimation;

  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _showPasswordField = false;
  bool _wifiSimStarted = false;

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

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _iconAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _iconController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _skipToApp() {
    ref.read(authStateProvider.notifier).completeOnboarding();
    ref.read(navigationProvider.notifier).changeTab(TabId.dashboard);
  }

  void _startWifiConnection() async {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text;
    if (ssid.isEmpty) return;

    ref.read(wifiSsidProvider.notifier).state = ssid;
    ref.read(wifiPasswordProvider.notifier).state = password;
    ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.connecting;

    final success = await ref.read(wifiSetupDatasourceProvider).configureDevice(
      ssid: ssid,
      password: password,
    );

    if (mounted) {
      if (success) {
        ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.connected;
      } else {
        ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.error;
      }
    }
  }

  void _startPairing() {
    ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.instruction;
  }

  void _verifyAndStartScanning() async {
    if (!mounted) return;
    ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.verifying;
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.scanning;
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;
    // Inyectar redes falsas y saltar directo a connecting con SSID pre-elegido
    ref.read(wifiNetworksProvider.notifier).state = const [
      _WifiNetwork(ssid: 'GossipGarden_Home', signal: 4, secured: true),
      _WifiNetwork(ssid: 'CasaDeAngelo_5G',   signal: 3, secured: true),
      _WifiNetwork(ssid: 'Vecinos_WiFi',       signal: 2, secured: true),
    ];
    ref.read(wifiSsidProvider.notifier).state = 'GossipGarden_Home';
    _ssidController.text = 'GossipGarden_Home';
    _passwordController.text = '••••••••';
    ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.connecting;
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;
    ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.connected;
  }

  void _scanNetworks() async {
    ref.read(wifiScanningProvider.notifier).state = true;
    // Simula que le pedimos al chip que refresque la lista
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ref.read(wifiScanningProvider.notifier).state = false;
    }
  }

  void _selectNetwork(_WifiNetwork net) {
    _ssidController.text = net.ssid;
    setState(() => _showPasswordField = true);
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(onboardingStepProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    final isFirstStep = step == OnboardingStep.wow;
    final isLastStep = step == OnboardingStep.config;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
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

            // ── Botón Skip ──────────────────────────────────────────────
            if (!isFirstStep && !isLastStep)
              Positioned(
                top: 8,
                right: 8,
                child: TextButton(
                  onPressed: _skipToApp,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black45,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        OnboardingStep.values.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i <= index ? const Color(0xFF4A6741) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(OnboardingStep step, NavigationNotifier navNotifier) {
    switch (step) {
      case OnboardingStep.wow:
        return _buildWowStep();
      case OnboardingStep.welcome:
        return _buildWelcomeStep();
      case OnboardingStep.connect:
        return _buildWifiSetupStep();
      case OnboardingStep.identify:
        return _buildIdentifyStep();
      case OnboardingStep.firstInsight:
        return _buildFirstInsightStep();
      case OnboardingStep.config:
        return _buildConfigStep(navNotifier);
    }
  }

  // ── Paso 1: Wow ─────────────────────────────────────────────────────────

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
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                colors: [Color(0xFF4A6741), Color(0xFF8BC34A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 25,
                )
              ],
            ),
            child: const Icon(Icons.local_florist,
                size: 100, color: Colors.white),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icons.water_drop,
            Icons.wb_sunny,
            Icons.thermostat,
          ].map((e) {
            return AnimatedBuilder(
              animation: _iconAnimation,
              builder: (_, __) => Transform.scale(
                scale: _iconAnimation.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(e, size: 32, color: Color(0xFF4A6741)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        const Text(
          'Tus plantas tienen algo que decirte',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A6741)),
        ),
        const SizedBox(height: 48),
        _primaryButton('Quiero escucharlas', () {
          ref.read(onboardingStepProvider.notifier).state =
              OnboardingStep.welcome;
        }),
      ],
    );
  }

  // ── Paso 2: Bienvenida ──────────────────────────────────────────────────

  Widget _buildWelcomeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _card(
          child: Column(
            children: [
              _buildBenefitRow(FontAwesomeIcons.commentDots, 'Plantas hablan',
                  'Escucha lo que necesitan'),
              const SizedBox(height: 16),
              _buildBenefitRow(FontAwesomeIcons.towerBroadcast, 'Sensores',
                  'Monitoreo en tiempo real'),
              const SizedBox(height: 16),
              _buildBenefitRow(
                  FontAwesomeIcons.brain, 'IA', 'Predicciones inteligentes'),
            ],
          ),
        ),
        const SizedBox(height: 48),
        _primaryButton('Continuar', () {
          ref.read(onboardingStepProvider.notifier).state =
              OnboardingStep.connect;
          _startPairing();
        }),
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
                  color: const Color(0xFF4A6741).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.sensors, size: 28, color: Color(0xFF4A6741)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Conecta tus sensores',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('Elige tu red WiFi para configurar el dispositivo IoT',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
                      color: Colors.grey.shade700,
                      letterSpacing: 0.5)),
              TextButton.icon(
                onPressed: scanning ? null : _scanNetworks,
                icon: scanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A6741))))
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(scanning ? 'Buscando...' : 'Buscar'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4A6741),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.wifi_find, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text('Toca para buscar redes',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
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
                border: Border.all(color: const Color(0xFF4A6741).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A6741))),
                  const SizedBox(height: 14),
                  Text('Buscando redes cercanas...',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
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

          // ── Campo SSID manual ────────────────────────────────────────
          _wifiTextField(
            controller: _ssidController,
            label: 'Nombre de la red',
            hint: 'O escribe el nombre manualmente',
            icon: Icons.wifi,
            obscure: false,
            onChanged: (_) => setState(() => _showPasswordField = true),
          ),
          const SizedBox(height: 12),

          // Campo contraseña (se muestra al seleccionar red o escribir)
          if (_showPasswordField) ...[
            _wifiTextField(
              controller: _passwordController,
              label: 'Contraseña',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: !_passwordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.security_rounded, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tu contraseña se envía únicamente al sensor. Nunca pasa por nuestros servidores.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          ValueListenableBuilder(
            valueListenable: _ssidController,
            builder: (_, val, __) => _primaryButton(
              'Conectar sensor',
              val.text.trim().isEmpty ? null : () => _startWifiConnection(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNetworkTile(_WifiNetwork net, bool isLast, bool isSelected) {
    final signalIcon = [
      Icons.network_wifi_1_bar,
      Icons.network_wifi_2_bar,
      Icons.network_wifi_3_bar,
      Icons.signal_wifi_4_bar,
    ][net.signal.clamp(1, 4) - 1];

    final signalColor = net.signal >= 3 ? const Color(0xFF4A6741) : Colors.orange;

    return GestureDetector(
      onTap: () => _selectNetwork(net),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A6741).withOpacity(0.06) : Colors.transparent,
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
                                  ? Colors.grey.shade500
                                  : Colors.orange.shade700),
                        ),
                      ],
                    ),
                  ),
                  if (net.secured)
                    Icon(Icons.lock_rounded, size: 16, color: Colors.grey.shade400),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.check_circle_rounded,
                          size: 20, color: const Color(0xFF4A6741)),
                    ),
                ],
              ),
            ),
            if (!isLast)
              Divider(height: 1, indent: 52, color: Colors.grey.shade100),
          ],
        ),
      ),
    );
  }

  Widget _wifiTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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
        prefixIcon: Icon(icon, color: const Color(0xFF4A6741), size: 20),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(color: Color(0xFF4A6741)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4A6741), width: 2),
        ),
      ),
    );
  }

  Widget _buildWifiInstruction() {
    if (!_wifiSimStarted) {
      _wifiSimStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) _verifyAndStartScanning();
      });
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_lock_rounded, size: 64, color: Color(0xFF4A6741)),
        const SizedBox(height: 24),
        const Text(
          'Configuración del Sensor',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _card(
          child: const Column(
            children: [
              Text(
                'Conectando con el sensor...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 12),
              Text(
                'gossip_garden',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6741),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        const CircularProgressIndicator(color: Color(0xFF4A6741)),
      ],
    );
  }

  Widget _buildWifiVerifying() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF4A6741)),
          const SizedBox(height: 32),
          const Text(
            'Sincronizando con el sensor...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('Recibiendo endpoints de configuración'),
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
              color: Colors.blue.withOpacity(0.1),
            ),
            child: const Icon(Icons.wifi_find_rounded,
                size: 64, color: Colors.blue),
          ),
          const SizedBox(height: 32),
          const Text(
            'Conectado al sensor',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: Colors.blue),
          ),
          const SizedBox(height: 12),
          Text(
            'El chip está buscando redes WiFi reales\nen tu entorno...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 48),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
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
                color: Colors.orange.withOpacity(0.1),
              ),
              child: const Icon(Icons.cloud_upload_rounded,
                  size: 64, color: Colors.orange),
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
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 40),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
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
              color: Colors.green.withOpacity(0.1),
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                size: 64, color: Colors.green),
          ),
          const SizedBox(height: 32),
          const Text(
            '¡Chip en línea!',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.green),
          ),
          const SizedBox(height: 12),
          Text(
            'El chip se conectó a "$ssid"\ny ya está enviando datos de los sensores.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: const Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.red),
          ),
          const SizedBox(height: 32),
          const Text(
            'Error de configuración',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: Colors.red),
          ),
          const SizedBox(height: 12),
          Text(
            'El chip no pudo conectarse a la red WiFi.\nVerifica la contraseña e intenta de nuevo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 48),
          _primaryButton('Reintentar', () {
            ref.read(wifiSetupPhaseProvider.notifier).state = _WifiPhase.instruction;
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _card(
          child: const Text(
            'Hola. Soy Monducuru, una Opuntia monacantha. Mi tierra está al 31% — exactamente como me gusta. No me eches agua todavía.',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
        ),
        const SizedBox(height: 48),
        _primaryButton('Continuar', () {
          ref.read(onboardingStepProvider.notifier).state =
              OnboardingStep.config;
        })
      ],
    );
  }

  // ── Paso 6: Configuración notificaciones ────────────────────────────────

  Widget _buildConfigStep(NavigationNotifier nav) {
    final selected = ref.watch(notificationPreferenceProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Notificaciones',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
        _radioOption('important', 'Solo importantes', selected),
        const SizedBox(height: 16),
        _radioOption('all', 'Todas', selected),
        const SizedBox(height: 48),
        _primaryButton('A escucharlas', () {
          ref.read(authStateProvider.notifier).completeOnboarding();
          nav.changeTab(TabId.dashboard);
        }),
      ],
    );
  }

  // ── Widgets helpers ─────────────────────────────────────────────────────

  Widget _radioOption(String value, String label, String selected) {
    return GestureDetector(
      onTap: () {
        ref.read(notificationPreferenceProvider.notifier).state = value;
      },
      child: _card(
        child: Row(
          children: [
            Icon(
              selected == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: const Color(0xFF4A6741),
            ),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF4A6741)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ],
        )
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
          backgroundColor: enabled
              ? const Color(0xFF4A6741)
              : Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: enabled ? Colors.white : Colors.grey.shade500)),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
          )
        ],
      ),
      child: child,
    );
  }
}
