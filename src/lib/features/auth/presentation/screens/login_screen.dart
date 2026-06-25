import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? errorMessage;

  const LoginScreen({super.key, this.errorMessage});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  // Animación de entrada
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // Indicadores visuales — solo informativos, NO bloquean el submit
  bool get _emailLooksValid =>
      RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim());
  // El backend decide si la contraseña es correcta — solo chequeamos que no esté vacía
  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _loginWithEmail() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return; // igual que el original

    ref
        .read(authStateProvider.notifier)
        .signInWithEmailAndPassword(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    final themeError = widget.errorMessage ??
        (authState.hasError ? authState.error.toString() : null);

    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      body: Stack(
        children: [
          SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo ajustado a 180px
                      Image.asset(
                        GardenIcons.logoWithText,
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entra para ver qué murmuran tus plantas',
                        textAlign: TextAlign.center,
                        style: GardenTextStyles.body.copyWith(
                          color: GardenColors.inkSoft,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 40),

                      if (themeError != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: GardenColors.heartRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: GardenColors.heartRed
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            themeError,
                            style: GardenTextStyles.bodySmall
                                .copyWith(color: GardenColors.heartRed),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Email Field
                      TextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_passwordFocus),
                        decoration: InputDecoration(
                          hintText: 'Correo electrónico',
                          hintStyle: GardenTextStyles.body
                              .copyWith(color: GardenColors.inkSoft),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.all(12),
                            child: GardenIcon(asset: GardenIcons.email, size: 22),
                          ),
                          suffixIcon: _emailController.text.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    _emailLooksValid
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 20,
                                    color: _emailLooksValid
                                        ? GardenColors.leafDark
                                        : GardenColors.heartRed
                                            .withValues(alpha: 0.7),
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: GardenColors.dustLight, width: 1.2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: _emailController.text.isNotEmpty
                                  ? (_emailLooksValid
                                      ? GardenColors.leafDark.withValues(alpha: 0.5)
                                      : GardenColors.heartRed.withValues(alpha: 0.4))
                                  : GardenColors.dustLight,
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                                color: GardenColors.leafDark, width: 2),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 20),
                        ),
                        style: GardenTextStyles.body,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _canSubmit ? _loginWithEmail() : null,
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          hintStyle: GardenTextStyles.body
                              .copyWith(color: GardenColors.inkSoft),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.all(12),
                            child: GardenIcon(asset: GardenIcons.lock, size: 22),
                          ),
                          suffixIcon: IconButton(
                            icon: GardenIcon(
                              asset: _obscurePassword
                                  ? GardenIcons.eyeClose
                                  : GardenIcons.eyeOpen,
                              size: 22,
                              opacity: 0.6,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: GardenColors.dustLight, width: 1.2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: GardenColors.dustLight,
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                                color: GardenColors.leafDark, width: 2),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 20),
                        ),
                        style: GardenTextStyles.body,
                      ),
                      const SizedBox(height: 32),

                      // Iniciar Sesión Button — desactivado si los campos están vacíos
                      ElevatedButton(
                        onPressed: (isLoading || !_canSubmit)
                            ? null
                            : _loginWithEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GardenColors.leafDark,
                          disabledBackgroundColor: GardenColors.dustLight,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: GardenColors.inkSoft,
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
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Iniciar Sesión',
                                style: GardenTextStyles.title.copyWith(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: GardenColors.inkSoft.withValues(alpha: 0.2),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'O entra con',
                              style: GardenTextStyles.bodySmall.copyWith(
                                color: GardenColors.inkSoft,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: GardenColors.inkSoft.withValues(alpha: 0.2),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Google Login Button
                      ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => ref
                                .read(authStateProvider.notifier)
                                .signInWithGoogle(),
                        icon: const GardenIcon(asset: GardenIcons.google, size: 20),
                        label: Text(
                          'Google',
                          style: GardenTextStyles.title.copyWith(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: GardenColors.ink,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: GardenColors.inkSoft.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes cuenta? ',
                            style: GardenTextStyles.body
                                .copyWith(color: GardenColors.inkSoft),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Regístrate',
                              style: GardenTextStyles.title
                                  .copyWith(color: GardenColors.leafDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: GardenColors.creamPaper.withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: GardenColors.leafDark,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Abriendo el jardín...',
                        style: GardenTextStyles.title.copyWith(
                          color: GardenColors.leafDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
