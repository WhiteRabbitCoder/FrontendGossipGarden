import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? errorMessage;

  const LoginScreen({super.key, this.errorMessage});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginWithEmail() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    
    ref.read(authStateProvider.notifier).signInWithEmailAndPassword(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    final themeError = widget.errorMessage ?? (authState.hasError ? authState.error.toString() : null);

    return Scaffold(
      backgroundColor: GardenColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  // Logo Orgánico Crayola
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: GardenColors.sageLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GardenColors.sage,
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.park_rounded,
                        size: 64,
                        color: GardenColors.forest,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Título
                  Text(
                    'Gossip Garden',
                    textAlign: TextAlign.center,
                    style: GardenTextStyles.display.copyWith(
                      color: GardenColors.forest,
                      fontSize: 48,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entra para ver qué murmuran tus plantas',
                    textAlign: TextAlign.center,
                    style: GardenTextStyles.body.copyWith(
                      color: GardenColors.earth,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),

                  if (themeError != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: GardenColors.errorRose.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GardenColors.errorRose.withOpacity(0.3)),
                      ),
                      child: Text(
                        themeError,
                        style: GardenTextStyles.bodySmall.copyWith(color: GardenColors.errorRose),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Email Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Correo electrónico',
                      hintStyle: GardenTextStyles.body.copyWith(color: GardenColors.dust),
                      prefixIcon: const Icon(Icons.email_outlined, color: GardenColors.moss),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    style: GardenTextStyles.body,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      hintStyle: GardenTextStyles.body.copyWith(color: GardenColors.dust),
                      prefixIcon: const Icon(Icons.lock_outline, color: GardenColors.moss),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: GardenColors.dust,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    style: GardenTextStyles.body,
                  ),
                  const SizedBox(height: 32),

                  // Iniciar Sesión Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _loginWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GardenColors.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Iniciar Sesión', style: GardenTextStyles.title.copyWith(color: Colors.white, fontSize: 20)),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: GardenColors.dustLight, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('O entra con', style: GardenTextStyles.bodySmall.copyWith(color: GardenColors.dust)),
                      ),
                      Expanded(child: Divider(color: GardenColors.dustLight, thickness: 1)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Google Login Button
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : () => ref.read(authStateProvider.notifier).signInWithGoogle(),
                    icon: const FaIcon(FontAwesomeIcons.google, size: 20),
                    label: Text('Google', style: GardenTextStyles.title.copyWith(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: GardenColors.charcoal,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: GardenColors.dustLight, width: 1),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('¿No tienes cuenta? ', style: GardenTextStyles.body.copyWith(color: GardenColors.dust)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                        },
                        child: Text(
                          'Regístrate',
                          style: GardenTextStyles.title.copyWith(color: GardenColors.forest),
                        ),
                      ),
                    ],
                  ),
                ],
            ),
          ),
        ),
      ),
    );
  }
}
