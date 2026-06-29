import 'package:flutter/material.dart';
import '../../../../core/utils/garden_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';

import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';

class InviteFriendScreen extends ConsumerStatefulWidget {
  const InviteFriendScreen({super.key});

  @override
  ConsumerState<InviteFriendScreen> createState() => _InviteFriendScreenState();
}

class _InviteFriendScreenState extends ConsumerState<InviteFriendScreen> {
  final _joinCodeController = TextEditingController();
  bool _isJoining = false;

  // HARDCODE(demo): código, URL y unión simulada (delay + validación local).
  // TODO(backend): GET /invites/mine, POST /invites/join y deep links reales.
  static const _demoInviteCode = 'GARDEN-7K2M';
  static const _inviteBaseUrl = 'https://gossipgarden.app/invite';

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  String _inviteLink(String code) => '$_inviteBaseUrl/$code';

  String _inviteMessage(String userName, String code) {
    return '$userName te invita a su jardín en Gossip Garden. '
        'Únete con este enlace: ${_inviteLink(code)}';
  }

  Future<void> _copyToClipboard(String text, String feedback) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    GardenSnackbar.show(context, message: '');
  }

  Future<void> _joinWithCode() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      GardenSnackbar.show(context, message: 'Introduce un código de invitación.');
      return;
    }

    setState(() => _isJoining = true);
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _isJoining = false);

    GardenSnackbar.show(context, message: '');

    if (code == _demoInviteCode || code.length >= 6) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authSession = ref.watch(authStateProvider).value;
    final displayName = authSession?.profile?.displayName;
    final userName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : (authSession?.profile?.email?.split('@').first ?? 'Jardinero');
    final inviteLink = _inviteLink(_demoInviteCode);
    final inviteMessage = _inviteMessage(userName, _demoInviteCode);

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
              'Invitar amigo jardinero',
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Comparte tu jardín o únete con un código',
              style:
                  GardenTextStyles.label.copyWith(color: GardenColors.inkSoft),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: GardenColors.leafDark,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: GardenColors.creamLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child:
                        GardenIcon(asset: GardenIcons.friendPlants, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Haz crecer la comunidad verde',
                  style: GardenTextStyles.title.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Invita a quien quieras para que vea tus plantas, logros y consejos de cuidado.',
                  style: GardenTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'TU INVITACIÓN',
            style: GardenTextStyles.label.copyWith(
              color: GardenColors.inkSoft,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GardenColors.creamPaper),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Código personal',
                  style: GardenTextStyles.label.copyWith(
                    color: GardenColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _demoInviteCode,
                        style: GardenTextStyles.title.copyWith(
                          color: GardenColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(
                        _demoInviteCode,
                        'Código copiado al portapapeles.',
                      ),
                      icon:
                          const GardenIcon(asset: GardenIcons.pencil, size: 22),
                      tooltip: 'Copiar código',
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'Enlace para compartir',
                  style: GardenTextStyles.label.copyWith(
                    color: GardenColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  inviteLink,
                  style: GardenTextStyles.bodySmall.copyWith(
                    color: GardenColors.leafDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyToClipboard(
                          inviteLink,
                          'Enlace copiado al portapapeles.',
                        ),
                        icon: const GardenIcon(
                            asset: GardenIcons.wifiConnect, size: 18),
                        label: const Text('Copiar enlace'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GardenColors.leafDark,
                          side: const BorderSide(color: GardenColors.leafGreen),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _copyToClipboard(
                          inviteMessage,
                          'Mensaje copiado. Pégalo en WhatsApp o donde quieras.',
                        ),
                        icon: const GardenIcon(
                            asset: GardenIcons.share, size: 18),
                        label: const Text('Compartir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GardenColors.leafDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'UNIRSE A UN JARDÍN',
            style: GardenTextStyles.label.copyWith(
              color: GardenColors.inkSoft,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GardenColors.creamPaper),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Tienes un código de invitación?',
                  style: GardenTextStyles.bodySmall.copyWith(
                    color: GardenColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _joinCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Ej. GARDEN-7K2M',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: GardenIcon(asset: GardenIcons.lock, size: 20),
                    ),
                    filled: true,
                    fillColor: GardenColors.creamPaper,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isJoining ? null : _joinWithCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GardenColors.leafDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isJoining
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Unirme al jardín'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: GardenColors.leafGreen.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GardenIcon(asset: GardenIcons.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tus amigos podrán ver tus plantas destacadas y logros. '
                    'Puedes cambiar la visibilidad en Ajustes → Privacidad.',
                    style: GardenTextStyles.bodySmall.copyWith(
                      color: GardenColors.inkSoft,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
