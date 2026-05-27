import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/plants/presentation/screens/main_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/plants/presentation/screens/onboarding_screen.dart';
import 'core/observers/session_observer.dart';
import 'core/services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.ensureInitialized();
  runApp(ProviderScope(observers: [SessionObserver()], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFDFCF8),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A6741)),
      ),
      home: const _AppGate(),
    );
  }
}

class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (session) {
        if (session.profile == null) {
          return const LoginScreen();
        }

        if (!session.onboardingCompleted) {
          return const OnboardingScreen();
        }

        return const MainScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => LoginScreen(errorMessage: error.toString()),
    );
  }
}
