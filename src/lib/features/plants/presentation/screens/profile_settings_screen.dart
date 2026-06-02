import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';
import 'personal_info_screen.dart';

// ── Local providers (sin cambios) ────────────────────────────────────────────
final favoritePlantsProvider =
    StateProvider<List<String>>((ref) => ['1', '2']);

// ── Pantalla de perfil ────────────────────────────────────────────────────────────

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final favorites = ref.watch(favoritePlantsProvider);
    final authSession = ref.watch(authStateProvider).value;


// logica para traer el nombre del usuario 

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
                      onEditTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PersonalInfoScreen(),
                          ),
                        );
                      },
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
                  child: _AchievementsSection(),
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
  final VoidCallback onEditTap;
  final VoidCallback onSettingsTap;

  const _ProfileHeader({
    required this.userName,
    required this.plantCount,
    required this.onEditTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: GardenColors.creamLight,
            shape: BoxShape.circle,
            border: Border.all(color: GardenColors.leafGreen, width: 2),
          ),
          child: const Center(
            // TODO(backend): reemplazar con Image.network(authSession.profile.photoUrl)
            child: Text('🧑‍🌾', style: TextStyle(fontSize: 32)),
          ),
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
        // Botones editar + ajustes
        Column(
          children: [
            _IconCircleButton(
              icon: Icons.edit_outlined,
              onTap: onEditTap,
            ),
            const SizedBox(height: 8),
            _IconCircleButton(
              icon: Icons.settings_outlined,
              onTap: onSettingsTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconCircleButton({required this.icon, required this.onTap});

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
        child: Icon(icon, size: 18, color: GardenColors.ink),
      ),
    );
  }
}

// ── Achievements Section ──────────────────────────────────────────────────────
// TODO(backend): traer logros desde endpoint de achievements cuando esté disponible

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection();

  static const _achievements = [
    (icon: '🏅', label: 'Rey de la Lluvia', locked: false, progress: null as int?, total: null as int?),
    (icon: '🎖️', label: 'Pulgar Verde', locked: false, progress: null as int?, total: null as int?),
    (icon: '🔬', label: 'Científico Botánico', locked: true, progress: 12, total: 20),
  ];

  @override
  Widget build(BuildContext context) {
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
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _achievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final a = _achievements[index];
              return _AchievementCard(
                icon: a.icon,
                label: a.label,
                locked: a.locked,
                progress: a.progress,
                total: a.total,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String icon;
  final String label;
  final bool locked;
  final int? progress;
  final int? total;

  const _AchievementCard({
    required this.icon,
    required this.label,
    required this.locked,
    this.progress,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GardenColors.creamPaper),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: GardenColors.inkSoft),
            ],
          ),
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GardenTextStyles.label.copyWith(
              color: GardenColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (locked && progress != null && total != null) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress! / total!,
                minHeight: 4,
                backgroundColor: GardenColors.creamLight,
                color: GardenColors.leafGreen,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$progress/$total',
              style: GardenTextStyles.label.copyWith(
                color: GardenColors.inkSoft,
                fontSize: 9,
              ),
            ),
          ],
        ],
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
            child: const Icon(Icons.park_rounded,
                color: GardenColors.leafDark, size: 26),
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
          const Icon(Icons.chevron_right_rounded,
              color: GardenColors.inkSoft, size: 22),
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
            const Icon(Icons.add_rounded, color: GardenColors.leafDark, size: 20),
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
                    child: const Icon(Icons.park_rounded,
                        size: 20, color: GardenColors.leafDark),
                  ),
                  title: Text(plant.name),
                  subtitle: Text(plant.species),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_rounded,
                        color: GardenColors.leafDark),
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

  @override
  Widget build(BuildContext context) {
    final authSession = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: GardenColors.ink),
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
                icon: Icons.person_outline_rounded,
                title: 'Información personal',
                subtitle: 'Nombre, bio, avatar',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PersonalInfoScreen(),
                    ),
                  );
                },
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.mail_outline_rounded,
                title: 'Correo electrónico',
                subtitle: authSession?.profile?.email ?? '',
                onTap: () {},
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Contraseña',
                subtitle: 'Última actualización hace 2 meses',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── NOTIFICACIONES ───────────────────────────────────────────────
          _SettingsSectionHeader(label: 'NOTIFICACIONES'),
          _SettingsGroup(
            children: [
              _SettingsToggleTile(
                icon: Icons.smartphone_outlined,
                title: 'Notificaciones push',
                subtitle: 'Avisos en este dispositivo',
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
              ),
              _SettingsDivider(),
              _SettingsToggleTile(
                icon: Icons.mail_outline_rounded,
                title: 'Correo',
                subtitle: 'Resumen semanal por email',
                value: _emailNotifications,
                onChanged: (v) => setState(() => _emailNotifications = v),
              ),
              _SettingsDivider(),
              _SettingsToggleTile(
                icon: Icons.notifications_none_rounded,
                title: 'Recordatorios de cuidado',
                subtitle: 'Cuando una planta necesita atención',
                value: _careReminders,
                onChanged: (v) => setState(() => _careReminders = v),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── PRIVACIDAD Y SEGURIDAD ───────────────────────────────────────
          _SettingsSectionHeader(label: 'PRIVACIDAD Y SEGURIDAD'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Privacidad de datos',
                subtitle: 'Gestiona cómo usamos tu información',
                onTap: () {},
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.visibility_outlined,
                title: 'Visibilidad del perfil',
                subtitle: 'Quién puede ver tu jardín',
                onTap: () {},
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.security_outlined,
                title: 'Autenticación en dos pasos',
                subtitle: 'Añade una capa de seguridad',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── SOPORTE ──────────────────────────────────────────────────────
          _SettingsSectionHeader(label: 'SOPORTE'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Centro de ayuda',
                subtitle: 'Preguntas frecuentes y guías',
                onTap: () {},
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Contactar soporte',
                subtitle: 'Escríbenos, respondemos en 24h',
                onTap: () {},
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.star_outline_rounded,
                title: 'Calificar la app',
                subtitle: 'Tu opinión nos ayuda a mejorar',
                onTap: () {},
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
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
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
              child: Icon(icon, size: 18, color: GardenColors.ink),
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
            const Icon(Icons.chevron_right_rounded,
                color: GardenColors.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleTile({
    required this.icon,
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
            child: Icon(icon, size: 18, color: GardenColors.ink),
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
