import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';
import 'personal_info_screen.dart';
import 'help_center_screen.dart';
import 'contact_support_screen.dart';
import 'data_privacy_screen.dart';
import 'profile_visibility_screen.dart';
import 'sensor_settings_screen.dart';
import '../providers/achievement_providers.dart';
import '../widgets/profile_avatar.dart';
import '../../../../core/utils/store_launcher.dart';
import 'achievement_detail_screen.dart';
import '../../data/models/achievement.dart';

// ── Pantalla de perfil ────────────────────────────────────────────────────────────

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final favorites = ref.watch(favoritePlantsProvider);
    final authSession = ref.watch(authStateProvider).value;
    final localAvatarBytes = ref.watch(localAvatarBytesProvider);

    final displayName = authSession?.profile?.displayName;
    final userName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName
        : (authSession?.profile?.email?.split('@').first ?? 'Usuario');

    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      body: plantsAsync.when(
        data: (plants) {
          final favPlants =
              plants.where((p) => favorites.contains(p.id)).toList();

          return CustomScrollView(
            slivers: [
              // ── Header con usuario ────────────────────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _ProfileHeader(
                      userName: userName,
                      plantCount: plants.length,
                      photoUrl: authSession?.profile?.photoUrl,
                      localAvatarBytes: localAvatarBytes,
                      onSettingsTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Mis Logros ────────────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: AchievementsSection(),
                ),
              ),

              // ── Mis Plantas Favoritas ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: _FavoritePlantsSection(
                    favPlants: favPlants,
                    allPlants: plants,
                    favorites: favorites,
                    ref: ref,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: GardenColors.leafGreen)),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: GardenTextStyles.bodySmall)),
      ),
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String userName;
  final int plantCount;
  final String? photoUrl;
  final Uint8List? localAvatarBytes;
  final VoidCallback onSettingsTap;

  const _ProfileHeader({
    required this.userName,
    required this.plantCount,
    this.photoUrl,
    this.localAvatarBytes,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileAvatar(
          photoUrl: photoUrl,
          localBytes: localAvatarBytes,
          size: 68,
          fontSize: 32,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: GardenTextStyles.display.copyWith(
                  color: GardenColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Jardinera Intermedia · $plantCount plantas',
                style: GardenTextStyles.bodySmall.copyWith(
                  color: GardenColors.inkSoft,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '"Aprendiendo a hablar con plantas, una hoja a la vez."',
                style: GardenTextStyles.bodySmall.copyWith(
                  color: GardenColors.inkSoft,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _IconCircleButton(
          asset: GardenIcons.settings,
          onTap: onSettingsTap,
        ),
      ],
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  const _IconCircleButton({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: GardenColors.creamPaper),
        ),
        child: Center(child: GardenIcon(asset: asset, size: 18)),
      ),
    );
  }
}

// ── Achievements Section ──────────────────────────────────────────────────────

class AchievementsSection extends ConsumerStatefulWidget {
  const AchievementsSection({super.key});

  @override
  ConsumerState<AchievementsSection> createState() => _AchievementsSectionState();
}

class _AchievementsSectionState extends ConsumerState<AchievementsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(achievementStatsProvider.notifier).recordLoginSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementProgressListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis Logros',
          style: GardenTextStyles.title.copyWith(
            color: GardenColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        achievementsAsync.when(
          loading: () => const SizedBox(
            height: 132,
            child: Center(
              child: CircularProgressIndicator(color: GardenColors.leafGreen),
            ),
          ),
          error: (e, _) => SizedBox(
            height: 132,
            child: Center(
              child: Text('Error al cargar logros', style: GardenTextStyles.bodySmall),
            ),
          ),
          data: (achievements) => SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return AchievementCard(
                  progress: achievements[index],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AchievementDetailScreen(
                          progress: achievements[index],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class AchievementCard extends StatelessWidget {
  final AchievementProgress progress;
  final VoidCallback onTap;

  const AchievementCard({
    super.key,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final def = progress.definition;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: progress.unlocked
                ? GardenColors.golden.withOpacity(0.5)
                : GardenColors.dustLight,
          ),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GardenIcon(
                asset: progress.unlocked
                    ? GardenIcons.logroDesbloqueado
                    : GardenIcons.info,
                size: 14,
                opacity: progress.unlocked ? 1.0 : 0.6,
              ),
            ),
            GardenIcon(
              asset: GardenIcons.achievementAsset(def.id),
              size: 30,
              opacity: progress.unlocked ? 1.0 : 0.45,
            ),
            const SizedBox(height: 2),
            Text(
              def.title,
              style: GardenTextStyles.label.copyWith(
                color: GardenColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.ratio,
                minHeight: 4,
                backgroundColor: GardenColors.creamLight,
                color: progress.unlocked
                    ? GardenColors.golden
                    : GardenColors.leafGreen,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${progress.displayCurrent}/${progress.goal}',
              style: GardenTextStyles.label.copyWith(
                color: GardenColors.inkSoft,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Favorite Plants Section ───────────────────────────────────────────────────

class _FavoritePlantsSection extends StatelessWidget {
  final List<Plant> favPlants;
  final List<Plant> allPlants;
  final List<String> favorites;
  final WidgetRef ref;

  const _FavoritePlantsSection({
    required this.favPlants,
    required this.allPlants,
    required this.favorites,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis Plantas Favoritas',
          style: GardenTextStyles.title.copyWith(
            color: GardenColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        ...favPlants.map((plant) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FavoritePlantRow(plant: plant),
            )),
        if (favorites.length < 3)
          _AddFavoriteButton(
            allPlants: allPlants,
            favorites: favorites,
            ref: ref,
          ),
      ],
    );
  }
}

class _FavoritePlantRow extends StatelessWidget {
  final Plant plant;
  const _FavoritePlantRow({required this.plant});

  String _personalityLabel(PlantPersonality p) {
    switch (p) {
      case PlantPersonality.dramatic:
        return '🌹 La dramática';
      case PlantPersonality.wise:
        return '🧘 La zen';
      case PlantPersonality.playful:
        return '🦋 El filósofo';
    }
  }

  Color _healthColor(double h) {
    if (h > 70) return GardenColors.okGreen;
    if (h > 40) return GardenColors.golden;
    return GardenColors.heartRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GardenColors.creamPaper),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: GardenColors.creamLight,
              shape: BoxShape.circle,
            ),
            child: const GardenIcon(
              asset: GardenIcons.plantEco,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.name,
                  style: GardenTextStyles.title.copyWith(
                    color: GardenColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _personalityLabel(plant.personality),
                  style: GardenTextStyles.label.copyWith(
                    color: GardenColors.inkSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${plant.health.toInt()}%',
                style: TextStyle(
                  color: _healthColor(plant.health),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'SALUD',
                style: GardenTextStyles.label.copyWith(
                  color: GardenColors.inkSoft,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const GardenIcon(
            asset: GardenIcons.forward,
            size: 22,
            opacity: 0.6,
          ),
        ],
      ),
    );
  }
}

class _AddFavoriteButton extends StatelessWidget {
  final List<Plant> allPlants;
  final List<String> favorites;
  final WidgetRef ref;

  const _AddFavoriteButton({
    required this.allPlants,
    required this.favorites,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final available = allPlants.where((p) => !favorites.contains(p.id)).toList();
    return GestureDetector(
      onTap: available.isEmpty
          ? null
          : () => _showModal(context, available),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GardenColors.creamLight, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GardenIcon(asset: GardenIcons.add, size: 20),
            const SizedBox(width: 8),
            Text(
              'Agregar planta favorita',
              style: GardenTextStyles.bodySmall.copyWith(
                color: GardenColors.leafDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModal(BuildContext context, List<Plant> available) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selecciona una planta',
                style: GardenTextStyles.title.copyWith(
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ...available.map((plant) => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: GardenColors.creamLight,
                      shape: BoxShape.circle,
                    ),
                    child: const GardenIcon(
                      asset: GardenIcons.plantEco,
                      size: 20,
                    ),
                  ),
                  title: Text(plant.name),
                  subtitle: Text(plant.species),
                  trailing: IconButton(
                    icon: const GardenIcon(asset: GardenIcons.add, size: 22),
                    onPressed: () {
                      ref.read(favoritePlantsProvider.notifier).state = [
                        ...ref.read(favoritePlantsProvider),
                        plant.id,
                      ];
                      Navigator.pop(context);
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Settings Screen ───────────────────────────────────────────────────────────

class _SettingsScreen extends ConsumerStatefulWidget {
  const _SettingsScreen();

  @override
  ConsumerState<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<_SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _careReminders = true;

  Future<void> _openPlayStore() async {
    final opened = await openPlayStoreListing();
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Play Store.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Ajustes',
                style: GardenTextStyles.title.copyWith(
                  color: GardenColors.ink,
                  fontWeight: FontWeight.w800,
                )),
            Text('Personaliza tu experiencia',
                style:
                    GardenTextStyles.label.copyWith(color: GardenColors.inkSoft)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          // ── CUENTA ──────────────────────────────────────────────────────
          _SettingsSectionHeader(label: 'CUENTA'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                iconAsset: GardenIcons.profile,
                title: 'Información personal',
                subtitle: 'Nombre, bio, avatar, contraseña',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PersonalInfoScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── NOTIFICACIONES ───────────────────────────────────────────────
          _SettingsSectionHeader(label: 'NOTIFICACIONES'),
          _SettingsGroup(
            children: [
              _SettingsToggleTile(
                iconAsset: GardenIcons.phone,
                title: 'Notificaciones push',
                subtitle: 'Avisos en este dispositivo',
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
              ),
              _SettingsDivider(),
              _SettingsToggleTile(
                iconAsset: GardenIcons.email,
                title: 'Correo',
                subtitle: 'Resumen semanal por email',
                value: _emailNotifications,
                onChanged: (v) => setState(() => _emailNotifications = v),
              ),
              _SettingsDivider(),
              _SettingsToggleTile(
                iconAsset: GardenIcons.notification,
                title: 'Recordatorios de cuidado',
                subtitle: 'Cuando una planta necesita atención',
                value: _careReminders,
                onChanged: (v) => setState(() => _careReminders = v),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── SENSORES ────────────────────────────────────────────────────
          _SettingsSectionHeader(label: 'SENSORES'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                iconAsset: GardenIcons.logroSensores,
                title: 'Mis sensores',
                subtitle: 'Estado, vinculación y configuración WiFi',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SensorSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── PRIVACIDAD Y SEGURIDAD ───────────────────────────────────────
          _SettingsSectionHeader(label: 'PRIVACIDAD Y SEGURIDAD'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                iconAsset: GardenIcons.shield,
                title: 'Privacidad de datos',
                subtitle: 'Gestiona cómo usamos tu información',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DataPrivacyScreen(),
                    ),
                  );
                },
              ),
              _SettingsDivider(),
              _SettingsTile(
                iconAsset: GardenIcons.eyeOpen,
                title: 'Visibilidad del perfil',
                subtitle: 'Quién puede ver tu jardín',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileVisibilityScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── SOPORTE ──────────────────────────────────────────────────────
          _SettingsSectionHeader(label: 'SOPORTE'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                iconAsset: GardenIcons.helpBooks,
                title: 'Centro de ayuda',
                subtitle: 'Preguntas frecuentes y guías',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HelpCenterScreen(),
                    ),
                  );
                },
              ),
              _SettingsDivider(),
              _SettingsTile(
                iconAsset: GardenIcons.chat,
                title: 'Contactar soporte',
                subtitle: 'Escríbenos, respondemos en 24h',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ContactSupportScreen(),
                    ),
                  );
                },
              ),
              _SettingsDivider(),
              _SettingsTile(
                iconAsset: GardenIcons.starOutline,
                title: 'Calificar la app',
                subtitle: 'Abre Google Play Store para valorarnos',
                onTap: _openPlayStore,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Cerrar sesión ────────────────────────────────────────────────
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              ref.read(authStateProvider.notifier).signOut();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: const Center(
                child: Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Color(0xFFD94040),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings helpers ──────────────────────────────────────────────────────────

class _SettingsSectionHeader extends StatelessWidget {
  final String label;
  const _SettingsSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GardenTextStyles.label.copyWith(
          color: GardenColors.inkSoft,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GardenColors.creamPaper),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: GardenColors.creamPaper,
      indent: 56,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: GardenColors.creamLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: GardenIcon(asset: iconAsset, size: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GardenTextStyles.bodySmall.copyWith(
                      color: GardenColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GardenTextStyles.label.copyWith(
                      color: GardenColors.inkSoft,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const GardenIcon(
              asset: GardenIcons.forward,
              size: 20,
              opacity: 0.6,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleTile({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: GardenColors.creamLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: GardenIcon(asset: iconAsset, size: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GardenTextStyles.bodySmall.copyWith(
                    color: GardenColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GardenTextStyles.label.copyWith(
                    color: GardenColors.inkSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: GardenColors.leafDark,
          ),
        ],
      ),
    );
  }
}
