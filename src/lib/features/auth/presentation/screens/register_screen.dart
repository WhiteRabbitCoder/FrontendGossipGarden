import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _register() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || password.isEmpty) return;
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    ref.read(authStateProvider.notifier).signInWithEmailAndPassword(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: GardenColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GardenColors.forest),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  Text(
                    'Crear cuenta',
                    textAlign: TextAlign.center,
                    style: GardenTextStyles.display.copyWith(
                      color: GardenColors.forest,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Únete a Gossip Garden',
                    textAlign: TextAlign.center,
                    style: GardenTextStyles.body.copyWith(color: GardenColors.earth),
                  ),
                  const SizedBox(height: 40),

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
                  const SizedBox(height: 16),

                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Confirmar contraseña',
                      hintStyle: GardenTextStyles.body.copyWith(color: GardenColors.dust),
                      prefixIcon: const Icon(Icons.lock_outline, color: GardenColors.moss),
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

                  ElevatedButton(
                    onPressed: isLoading ? null : _register,
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
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Crear cuenta',
                            style: GardenTextStyles.title.copyWith(color: Colors.white, fontSize: 20),
                          ),
                  ),
                ],
            ),
          ),
        ),
      ),
    );
  }
}
