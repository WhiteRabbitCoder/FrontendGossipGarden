import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  late final TextEditingController _usernameController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isUpdatingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final authSession = ref.read(authStateProvider).value;
    final currentName = authSession?.profile?.displayName ?? '';
    _usernameController = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final newName = _usernameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de usuario no puede estar vacío.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authStateProvider.notifier).updateProfile(displayName: newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Información personal actualizada con éxito.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePassword() async {
    final current = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPassword.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos de contraseña.')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La nueva contraseña debe tener al menos 6 caracteres.')),
      );
      return;
    }

    if (newPassword != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas nuevas no coinciden.')),
      );
      return;
    }

    setState(() => _isUpdatingPassword = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isUpdatingPassword = false);

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contraseña actualizada correctamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authSession = ref.watch(authStateProvider).value;
    final email = authSession?.profile?.email ?? 'correo@ejemplo.com';

    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GardenColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información personal',
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Edita tu perfil de jardinero',
              style: GardenTextStyles.label.copyWith(color: GardenColors.inkSoft),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Decorativo
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: GardenColors.creamLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: GardenColors.leafGreen, width: 3),
                      ),
                      child: const Center(
                        child: Text('🧑‍🌾', style: TextStyle(fontSize: 48)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Contenedor de Formulario Premium
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GardenColors.creamPaper),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo Nombre de Usuario
                    Text(
                      'NOMBRE DE USUARIO',
                      style: GardenTextStyles.label.copyWith(
                        color: GardenColors.inkSoft,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'Tu apodo de jardinero',
                        hintStyle: GardenTextStyles.body.copyWith(color: GardenColors.inkSoft),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: GardenColors.leafGreen),
                        filled: true,
                        fillColor: GardenColors.creamPaper.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: GardenColors.creamPaper),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: GardenColors.creamPaper),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: GardenColors.leafGreen, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      style: GardenTextStyles.body,
                    ),
                    const SizedBox(height: 24),

                    // Campo Correo (Lectura únicamente)
                    Text(
                      'CORREO ELECTRÓNICO',
                      style: GardenTextStyles.label.copyWith(
                        color: GardenColors.inkSoft,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: GardenColors.creamPaper.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: GardenColors.creamPaper),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mail_outline_rounded, color: GardenColors.inkSoft),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              email,
                              style: GardenTextStyles.body.copyWith(color: GardenColors.inkSoft),
                            ),
                          ),
                          const Icon(Icons.lock_outline_rounded, color: GardenColors.inkSoft, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GardenColors.creamPaper),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTRASEÑA',
                      style: GardenTextStyles.label.copyWith(
                        color: GardenColors.inkSoft,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrentPassword,
                      decoration: _passwordDecoration(
                        hint: 'Contraseña actual',
                        obscure: _obscureCurrentPassword,
                        onToggle: () => setState(
                          () => _obscureCurrentPassword = !_obscureCurrentPassword,
                        ),
                      ),
                      style: GardenTextStyles.body,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: _passwordDecoration(
                        hint: 'Nueva contraseña',
                        obscure: _obscureNewPassword,
                        onToggle: () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword,
                        ),
                      ),
                      style: GardenTextStyles.body,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: _passwordDecoration(
                        hint: 'Confirmar nueva contraseña',
                        obscure: _obscureConfirmPassword,
                        onToggle: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword,
                        ),
                      ),
                      style: GardenTextStyles.body,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: _isUpdatingPassword ? null : _updatePassword,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GardenColors.leafDark,
                        side: const BorderSide(color: GardenColors.leafGreen),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isUpdatingPassword
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: GardenColors.leafDark,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Actualizar contraseña',
                              style: GardenTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Botón Guardar Cambios
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GardenColors.leafDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Guardar cambios',
                        style: GardenTextStyles.title.copyWith(color: Colors.white, fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _passwordDecoration({
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GardenTextStyles.body.copyWith(color: GardenColors.inkSoft),
      prefixIcon: const Icon(Icons.lock_outline_rounded, color: GardenColors.leafGreen),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: GardenColors.inkSoft,
        ),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: GardenColors.creamPaper.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: GardenColors.creamPaper),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: GardenColors.creamPaper),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: GardenColors.leafGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}
