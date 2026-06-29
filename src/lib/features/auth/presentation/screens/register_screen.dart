import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _inlineError;

  // Animación de entrada
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // Validaciones
  bool get _emailValid =>
      RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim());
  bool get _passwordsMatch =>
      _passwordController.text == _confirmController.text &&
      _confirmController.text.isNotEmpty;

  /// 0 = vacío, 1 = débil, 2 = media, 3 = fuerte
  int get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(p)) score++;
    if (score <= 1) return 1;
    if (score <= 2) return 2;
    return 3;
  }

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _fadeAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _passwordController.addListener(() => setState(() {}));
    _confirmController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _register() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (username.isEmpty) {
      setState(() => _inlineError = 'Por favor, ingresa un nombre de usuario');
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      setState(() => _inlineError = 'Completa todos los campos');
      return;
    }
    if (!_emailValid) {
      setState(() => _inlineError = 'El correo electrónico no es válido');
      return;
    }
    if (password != confirm) {
      setState(() => _inlineError = 'Las contraseñas no coinciden');
      return;
    }
    setState(() => _inlineError = null);

    ref
        .read(authStateProvider.notifier)
        .registerWithEmailAndPassword(email, password, username);
  }

  String _cleanErrorMessage(Object error) {
    String msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      msg = msg.replaceFirst('Exception: ', '');
    }
    if (msg.contains('] ')) {
      msg = msg.split('] ').last;
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    // Escuchar cambios del provider para errores o éxito
    ref.listen<AsyncValue<AuthSession>>(authStateProvider, (previous, next) {
      if (next.hasError) {
        setState(() => _inlineError = _cleanErrorMessage(next.error!));
        if (previous?.hasError != true) {
          _passwordController.clear();
          _confirmController.clear();
        }
      } else if (!next.isLoading && next.value?.profile != null) {
        // Redirigir si la autenticación fue exitosa
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const GardenIcon(asset: GardenIcons.back, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Únete a Gossip Garden',
                    textAlign: TextAlign.center,
                    style: GardenTextStyles.display.copyWith(
                      color: GardenColors.leafDark,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Entra en el jardín!',
                    textAlign: TextAlign.center,
                    style: GardenTextStyles.body
                        .copyWith(color: GardenColors.inkSoft),
                  ),
                  const SizedBox(height: 40),


                      // ── Error inline ─────────────────────────────────────
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: _inlineError != null
                            ? Container(
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: GardenColors.heartRed
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: GardenColors.heartRed
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded,
                                        size: 18,
                                        color: GardenColors.heartRed),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _inlineError!,
                                        style: GardenTextStyles.bodySmall
                                            .copyWith(
                                                color: GardenColors.heartRed),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Username
                      _buildField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        nextFocus: _emailFocus,
                        hint: 'Nombre de usuario',
                        iconAsset: GardenIcons.profile,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      _buildField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        nextFocus: _passwordFocus,
                        hint: 'Correo electrónico',
                        iconAsset: GardenIcons.email,
                        keyboardType: TextInputType.emailAddress,
                        suffixIcon: _emailController.text.isNotEmpty
                            ? Icon(
                                _emailValid
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 20,
                                color: _emailValid
                                    ? GardenColors.leafDark
                                    : GardenColors.heartRed
                                        .withValues(alpha: 0.7),
                              )
                            : null,
                        activeBorderColor: _emailController.text.isNotEmpty
                            ? (_emailValid
                                ? GardenColors.leafDark.withValues(alpha: 0.5)
                                : GardenColors.heartRed.withValues(alpha: 0.4))
                            : GardenColors.dustLight,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      _buildField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        nextFocus: _confirmFocus,
                        hint: 'Contraseña',
                        iconAsset: GardenIcons.lock,
                        obscure: _obscurePassword,
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
                      ),

                      // Indicador de fortaleza de contraseña
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: _passwordController.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _buildPasswordStrength(),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 16),

                      // Confirmar contraseña
                      _buildField(
                        controller: _confirmController,
                        focusNode: _confirmFocus,
                        hint: 'Confirmar contraseña',
                        iconAsset: GardenIcons.lock,
                        obscure: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _register(),
                        activeBorderColor:
                            _confirmController.text.isNotEmpty
                                ? (_passwordsMatch
                                    ? GardenColors.leafDark
                                        .withValues(alpha: 0.5)
                                    : GardenColors.heartRed
                                        .withValues(alpha: 0.4))
                                : GardenColors.dustLight,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_confirmController.text.isNotEmpty)
                              Icon(
                                _passwordsMatch
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 20,
                                color: _passwordsMatch
                                    ? GardenColors.leafDark
                                    : GardenColors.heartRed
                                        .withValues(alpha: 0.7),
                              ),
                            IconButton(
                              icon: GardenIcon(
                                asset: _obscureConfirmPassword
                                    ? GardenIcons.eyeClose
                                    : GardenIcons.eyeOpen,
                                size: 22,
                                opacity: 0.6,
                              ),
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // CTA
                      ElevatedButton(
                        onPressed: isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GardenColors.leafDark,
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
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Crear cuenta',
                                style: GardenTextStyles.title.copyWith(
                                    color: Colors.white, fontSize: 20),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
  }

  /// Campo de texto con estilo Garden unificado.
  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String hint,
    required String iconAsset,
    bool obscure = false,
    Widget? suffixIcon,
    Color? activeBorderColor,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    final borderColor = activeBorderColor ?? GardenColors.dustLight;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted ??
          (nextFocus != null
              ? (_) => FocusScope.of(context).requestFocus(nextFocus)
              : null),
      style: GardenTextStyles.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GardenTextStyles.body.copyWith(color: GardenColors.inkSoft),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: GardenIcon(asset: iconAsset, size: 22),
        ),
        suffixIcon: suffixIcon != null
            ? Padding(padding: const EdgeInsets.only(right: 4), child: suffixIcon)
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide:
              const BorderSide(color: GardenColors.leafDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }

  /// Barra de fortaleza de contraseña animada.
  Widget _buildPasswordStrength() {
    final strength = _passwordStrength;
    final labels = ['', 'Débil', 'Media', 'Fuerte'];
    final colors = [
      Colors.transparent,
      GardenColors.heartRed,
      GardenColors.potOrange,
      GardenColors.leafDark,
    ];
    final label = labels[strength];
    final color = colors[strength];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            final filled = i < strength;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: filled ? color : GardenColors.dustLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GardenTextStyles.label.copyWith(color: color),
        ),
      ],
    );
  }
}
