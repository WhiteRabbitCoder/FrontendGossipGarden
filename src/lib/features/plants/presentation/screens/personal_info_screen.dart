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
  bool _isLoading = false;

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

  @override
  Widget build(BuildContext context) {
    final authSession = ref.watch(authStateProvider).value;
    final email = authSession?.profile?.email ?? 'correo@ejemplo.com';

    return Scaffold(
      backgroundColor: GardenColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GardenColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información personal',
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.charcoal,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Edita tu perfil de jardinero',
              style: GardenTextStyles.label.copyWith(color: GardenColors.dust),
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
                        color: GardenColors.sageLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: GardenColors.sage, width: 3),
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
                  border: Border.all(color: GardenColors.dustLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo Nombre de Usuario
                    Text(
                      'NOMBRE DE USUARIO',
                      style: GardenTextStyles.label.copyWith(
                        color: GardenColors.dust,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'Tu apodo de jardinero',
                        hintStyle: GardenTextStyles.body.copyWith(color: GardenColors.dust),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: GardenColors.moss),
                        filled: true,
                        fillColor: GardenColors.cream.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: GardenColors.dustLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: GardenColors.dustLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: GardenColors.sage, width: 2),
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
                        color: GardenColors.dust,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: GardenColors.cream.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: GardenColors.dustLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mail_outline_rounded, color: GardenColors.dust),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              email,
                              style: GardenTextStyles.body.copyWith(color: GardenColors.dust),
                            ),
                          ),
                          const Icon(Icons.lock_outline_rounded, color: GardenColors.dust, size: 16),
                        ],
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
                  backgroundColor: GardenColors.forest,
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
}
