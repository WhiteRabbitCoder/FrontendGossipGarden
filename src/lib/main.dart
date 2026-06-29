import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/api_client.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/plants/presentation/screens/main_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/plants/presentation/screens/onboarding_screen.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/theme/garden_colors.dart';
import 'core/theme/garden_text_styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: GardenColors.creamPaper,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GardenColors.heartRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: GardenColors.heartRed, width: 2),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: GardenColors.heartRed,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Se nos cayó la maceta!',
                style: GardenTextStyles.display.copyWith(
                  color: GardenColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Parece que perdimos la conexión con el jardín.',
                style: GardenTextStyles.body.copyWith(
                  color: GardenColors.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  };

  await FirebaseBootstrap.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A6741)),
      ),
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            color: GardenColors.creamPaper,
            image: DecorationImage(
              image: AssetImage('images/PaperTexture.png'),
              fit: BoxFit.cover,
              opacity: 0.4, // Aumentado a petición del usuario
            ),
          ),
          child: child!,
        );
      },
      home: const _AppGate(),
    );
  }
}

class _AppGate extends ConsumerStatefulWidget {
  const _AppGate();

  @override
  ConsumerState<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<_AppGate> {
  StreamSubscription? _unauthorizedSub;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _unauthorizedSub = ApiClient.onUnauthorized.listen((_) {
      ref.read(authStateProvider.notifier).signOut();
    });
  }

  @override
  void dispose() {
    _unauthorizedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (authState.hasValue) {
      _initialized = true;
    }

    if (!_initialized) {
      return const _SplashScreen();
    }

    final session = authState.valueOrNull;

    if (session == null || session.profile == null) {
      return const LoginScreen();
    }

    if (!session.onboardingCompleted) {
      return const OnboardingScreen();
    }

    return const MainScreen();
  }
}

/// Pantalla de splash con branding mientras se verifica la sesión.
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: child,
              ),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: GardenColors.leafDark.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'images/logo_no_text.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: GardenColors.leafDark,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
