import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gossip_garden/features/plants/presentation/providers/navigation_provider.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';

enum OnboardingStep { wow, welcome, connect, identify, firstInsight, config }

final onboardingStepProvider =
    StateProvider<OnboardingStep>((ref) => OnboardingStep.wow);

final connectionStatusProvider = StateProvider<String>((ref) => 'searching');

final notificationPreferenceProvider =
    StateProvider<String>((ref) => 'important');

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
    super.dispose();
  }

  void _simulateConnection() {
    ref.read(connectionStatusProvider.notifier).state = 'searching';

    Timer(const Duration(seconds: 1), () {
      ref.read(connectionStatusProvider.notifier).state = 'linking';
    });

    Timer(const Duration(seconds: 3), () {
      ref.read(connectionStatusProvider.notifier).state = 'connected';
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(onboardingStepProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final navNotifier = ref.read(navigationProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Padding(
            key: ValueKey(step),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: _buildStepContent(step, connectionStatus, navNotifier),
                ),
                const SizedBox(height: 24),
                _buildProgress(step),
              ],
            ),
          ),
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

  Widget _buildStepContent(OnboardingStep step, String connectionStatus,
      NavigationNotifier navNotifier) {
    switch (step) {
      case OnboardingStep.wow:
        return _buildWowStep();
      case OnboardingStep.welcome:
        return _buildWelcomeStep();
      case OnboardingStep.connect:
        return _buildConnectStep(connectionStatus);
      case OnboardingStep.identify:
        return _buildIdentifyStep();
      case OnboardingStep.firstInsight:
        return _buildFirstInsightStep();
      case OnboardingStep.config:
        return _buildConfigStep(navNotifier);
    }
  }

  Widget _buildWowStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (_, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: child,
            );
          },
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
            child:
                const Icon(Icons.local_florist, size: 100, color: Colors.white),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['💧', '☀️', '🌡️'].map((e) {
            return AnimatedBuilder(
              animation: _iconAnimation,
              builder: (_, __) => Transform.scale(
                scale: _iconAnimation.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(e, style: const TextStyle(fontSize: 32)),
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
        _primaryButton('🌱 Quiero escucharlas', () {
          ref.read(onboardingStepProvider.notifier).state =
              OnboardingStep.welcome;
        }),
      ],
    );
  }

  Widget _buildWelcomeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _card(
          child: Column(
            children: [
              _buildBenefitRow(
                  '💬', 'Plantas hablan', 'Escucha lo que necesitan'),
              const SizedBox(height: 16),
              _buildBenefitRow('📡', 'Sensores', 'Monitoreo en tiempo real'),
              const SizedBox(height: 16),
              _buildBenefitRow('🧠', 'IA', 'Predicciones inteligentes'),
            ],
          ),
        ),
        const SizedBox(height: 48),
        _primaryButton('Continuar', () {
          ref.read(onboardingStepProvider.notifier).state =
              OnboardingStep.connect;
          _simulateConnection();
        }),
      ],
    );
  }

  Widget _buildConnectStep(String status) {
    final map = {
      'searching': ['Buscando...', Colors.amber, Icons.wifi_find],
      'linking': ['Conectando...', Colors.blue, Icons.link],
      'connected': ['¡Conectado!', Colors.green, Icons.wifi],
    };

    final data = map[status]!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: (data[1] as Color).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(data[2] as IconData, size: 48, color: data[1] as Color),
        ),
        const SizedBox(height: 32),
        Text(data[0] as String,
            style: TextStyle(
                fontSize: 20,
                color: data[1] as Color,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 48),
        if (status == 'connected')
          _primaryButton('¡Mi planta está lista!', () {
            ref.read(onboardingStepProvider.notifier).state =
                OnboardingStep.identify;
          })
      ],
    );
  }

  Widget _buildIdentifyStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Identifica tu planta',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
        const SizedBox(height: 40),
        _option('📸', 'Tomar foto'),
        const SizedBox(height: 16),
        _option('🔍', 'Buscar'),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            ref.read(onboardingStepProvider.notifier).state =
                OnboardingStep.firstInsight;
          },
          child: const Text('No lo sé → usar perfil genérico'),
        )
      ],
    );
  }

  Widget _buildFirstInsightStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _card(
          child: const Text(
              '¡Hola! Soy tu Monstera 🌿\nMi tierra está al 28% y tengo sed'),
        ),
        const SizedBox(height: 48),
        _primaryButton('Continuar', () {
          ref.read(onboardingStepProvider.notifier).state =
              OnboardingStep.config;
        })
      ],
    );
  }

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
        _primaryButton('🌱 ¡A escucharlas!', () {
          ref.read(authStateProvider.notifier).completeOnboarding();
          nav.changeTab(TabId.dashboard);
        }),
      ],
    );
  }

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

  Widget _buildBenefitRow(String emoji, String title, String subtitle) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
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

  Widget _option(String icon, String text) {
    return _card(
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Text(text),
          const Spacer(),
          const Icon(Icons.chevron_right)
        ],
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A6741),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.white)),
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
