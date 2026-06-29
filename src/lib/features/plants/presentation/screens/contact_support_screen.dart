import 'package:flutter/material.dart';
import '../../../../core/utils/garden_snackbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // HARDCODE(demo): envío simulado con delay; no llama al backend.
  // TODO(backend): POST /support/tickets con asunto, mensaje y email del usuario.
  Future<void> _sendMessage() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      GardenSnackbar.show(context, message: 'Completa el asunto y el mensaje.');
      return;
    }

    setState(() => _isSending = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isSending = false);

    GardenSnackbar.show(context, message: 'Mensaje enviado. Te responderemos en menos de 24 horas.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authStateProvider).value?.profile?.email ?? '';

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
              'Contactar soporte',
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Escríbenos, respondemos en 24h',
              style: GardenTextStyles.label.copyWith(color: GardenColors.inkSoft),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      'CORREO DE CONTACTO',
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
                              email.isNotEmpty ? email : 'correo@ejemplo.com',
                              style: GardenTextStyles.body.copyWith(color: GardenColors.inkSoft),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ASUNTO',
                      style: GardenTextStyles.label.copyWith(
                        color: GardenColors.inkSoft,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _subjectController,
                      decoration: _inputDecoration(
                        hint: 'Ej. Problema con el sensor',
                        iconAsset: GardenIcons.pencil,
                      ),
                      style: GardenTextStyles.body,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'MENSAJE',
                      style: GardenTextStyles.label.copyWith(
                        color: GardenColors.inkSoft,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 6,
                      decoration: _inputDecoration(
                        hint: 'Describe tu consulta con el mayor detalle posible...',
                        iconAsset: GardenIcons.chat,
                      ),
                      style: GardenTextStyles.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSending ? null : _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GardenColors.leafDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Enviar mensaje',
                        style: GardenTextStyles.title.copyWith(color: Colors.white, fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required String iconAsset}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GardenTextStyles.body.copyWith(color: GardenColors.inkSoft),
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: GardenIcon(asset: iconAsset, size: 20),
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
