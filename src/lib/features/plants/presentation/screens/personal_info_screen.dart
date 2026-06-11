import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';
import '../providers/plant_providers.dart';
import '../widgets/profile_avatar.dart';

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
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isUpdatingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _localAvatarPath;

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

  Future<void> _pickAvatar() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    ref.read(localAvatarBytesProvider.notifier).state = bytes;
    setState(() => _localAvatarPath = file.path);
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
      await ref.read(authStateProvider.notifier).updateProfile(
            displayName: newName,
            photoUrl: _localAvatarPath,
          );
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

  // HARDCODE(demo): cambio de contraseña simulado; no valida la actual ni llama a Firebase/API.
  // TODO(backend): auth.updatePassword o endpoint de cambio de contraseña.
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
    final localBytes = ref.watch(localAvatarBytesProvider);
    final photoUrl = authSession?.profile?.photoUrl;

    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const GardenIcon(asset: GardenIcons.back, size: 20),
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
              Center(
                child: Stack(
                  children: [
                    ProfileAvatar(
                      photoUrl: photoUrl,
                      localBytes: localBytes,
                      size: 100,
                      fontSize: 48,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: GardenColors.leafDark,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const GardenIcon(
                            asset: GardenIcons.camera,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickAvatar,
                  child: Text(
                    'Cambiar foto',
                    style: GardenTextStyles.bodySmall.copyWith(
                      color: GardenColors.leafDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child: GardenIcon(asset: GardenIcons.profile, size: 20),
                        ),
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
                          const GardenIcon(asset: GardenIcons.email, size: 22, opacity: 0.6),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              email,
                              style: GardenTextStyles.body.copyWith(color: GardenColors.inkSoft),
                            ),
                          ),
                          const GardenIcon(asset: GardenIcons.lock, size: 16, opacity: 0.6),
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
      prefixIcon: const Padding(
        padding: EdgeInsets.all(12),
        child: GardenIcon(asset: GardenIcons.lock, size: 20),
      ),
      suffixIcon: IconButton(
        icon: GardenIcon(
          asset: obscure ? GardenIcons.eyeClose : GardenIcons.eyeOpen,
          size: 22,
          opacity: 0.6,
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
