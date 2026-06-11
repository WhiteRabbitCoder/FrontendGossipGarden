import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';
import '../providers/achievement_providers.dart';

// Flujo: método → cámara/búsqueda → resultado identificado → agregar
enum _IdentifyMode { select, camera, matches, search, result }

class PlantIdentifyScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCompleted;

  const PlantIdentifyScreen({super.key, this.onBack, this.onCompleted});

  @override
  ConsumerState<PlantIdentifyScreen> createState() => _PlantIdentifyScreenState();
}

class _PlantIdentifyScreenState extends ConsumerState<PlantIdentifyScreen> {
  _IdentifyMode _mode = _IdentifyMode.select;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _back() {
    if (_mode == _IdentifyMode.select) {
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.pop(context);
      }
    } else if (_mode == _IdentifyMode.matches) {
      setState(() => _mode = _IdentifyMode.camera);
    } else {
      setState(() => _mode = _IdentifyMode.select);
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
          onPressed: _back,
        ),
        title: Text(
          'Nueva planta',
          style: GardenTextStyles.title
              .copyWith(color: GardenColors.ink, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: GardenColors.creamPaper, height: 1),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_mode) {
      case _IdentifyMode.select:
        return _SelectMethodView(
          onCamera: () => setState(() => _mode = _IdentifyMode.camera),
          onSearch: () => setState(() => _mode = _IdentifyMode.search),
        );
      case _IdentifyMode.camera:
        return _CameraView(
          onIdentified: () => setState(() => _mode = _IdentifyMode.matches),
        );
      case _IdentifyMode.matches:
        return _MatchesView(
          onSelectMatch: () {
            ref.read(achievementStatsProvider.notifier).recordIdentification();
            setState(() => _mode = _IdentifyMode.result);
          },
        );
      case _IdentifyMode.search:
        return _SearchView(
          controller: _searchController,
          query: _searchQuery,
          onQueryChanged: (q) => setState(() => _searchQuery = q),
          onSelectPlant: () {
            ref.read(achievementStatsProvider.notifier).recordIdentification();
            setState(() => _mode = _IdentifyMode.result);
          },
        );
      case _IdentifyMode.result:
        return _ResultView(
          onAdd: widget.onCompleted ?? () => Navigator.pop(context),
        );
    }
  }
}

// ── 1. Seleccionar método ─────────────────────────────────────────────────────

class _SelectMethodView extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onSearch;
  const _SelectMethodView({required this.onCamera, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo quieres\nidentificarla?',
            style: GardenTextStyles.display.copyWith(
              color: GardenColors.ink,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Elige el método más cómodo para ti.',
            style: GardenTextStyles.bodySmall
                .copyWith(color: GardenColors.inkSoft),
          ),
          const SizedBox(height: 28),
          _MethodCard(
            iconAsset: GardenIcons.camera,
            title: 'Reconocer con cámara',
            subtitle: 'Toma o sube una foto y la identificamos por ti.',
            badge: 'Recomendado',
            onTap: onCamera,
          ),
          const SizedBox(height: 12),
          _MethodCard(
            iconAsset: GardenIcons.letters,
            title: 'Buscar por nombre',
            subtitle: 'Si ya sabes qué planta es, búscala en el catálogo.',
            onTap: onSearch,
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _MethodCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GardenColors.dustLight, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: GardenColors.ink.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                    color: GardenColors.creamLight, shape: BoxShape.circle),
                child: GardenIcon(asset: iconAsset, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GardenTextStyles.title.copyWith(
                          color: GardenColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GardenTextStyles.bodySmall
                          .copyWith(color: GardenColors.inkSoft, fontSize: 13),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            badge!,
                            style: GardenTextStyles.label.copyWith(
                                color: GardenColors.leafDark,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 2a. Cámara ────────────────────────────────────────────────────────────────

class _CameraView extends StatefulWidget {
  final VoidCallback onIdentified;
  const _CameraView({required this.onIdentified});

  @override
  State<_CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<_CameraView> {
  bool _scanning = false;

  Future<void> _identify() async {
    setState(() => _scanning = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) widget.onIdentified();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Placeholder de cámara
            Container(
              width: double.infinity,
              height: 360,
              decoration: BoxDecoration(
                color: GardenColors.creamLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _scanning
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: GardenColors.leafDark))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const GardenIcon(
                            asset: GardenIcons.camera,
                            size: 48,
                            opacity: 0.6),
                        const SizedBox(height: 10),
                        Text(
                          'Esperando imagen...',
                          style: GardenTextStyles.bodySmall
                              .copyWith(color: GardenColors.inkSoft),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _scanning ? null : _identify,
                icon: const GardenIcon(asset: GardenIcons.camera, size: 18),
                label: const Text('Abrir cámara',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GardenColors.leafDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: GardenColors.leafGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2b. Búsqueda por nombre ───────────────────────────────────────────────────

class _SearchView extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSelectPlant;

  const _SearchView({
    required this.controller,
    required this.query,
    required this.onQueryChanged,
    required this.onSelectPlant,
  });

  //hardcoded — TODO(backend): conectar endpoint de catálogo de plantas
  static const _catalog = [
    (
      emoji: '🌿',
      name: 'Monstera',
      species: 'Monstera Deliciosa',
      level: 'Fácil'
    ),
    (emoji: '🍃', name: 'Potos', species: 'Epipremnum Aureum', level: 'Fácil'),
    (
      emoji: '🌳',
      name: 'Ficus Lyrata',
      species: 'Ficus Lyrata',
      level: 'Exigente'
    ),
    (
      emoji: '🌵',
      name: 'Suculenta Echeveria',
      species: 'Echeveria Elegans',
      level: 'Fácil'
    ),
    (
      emoji: '🪴',
      name: 'Sansevieria',
      species: 'Dracaena Trifasciata',
      level: 'Fácil'
    ),
    (
      emoji: '🌱',
      name: 'Calathea',
      species: 'Calathea Orbifolia',
      level: 'Exigente'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _catalog
        .where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.species.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: TextField(
            controller: controller,
            onChanged: onQueryChanged,
            style: GardenTextStyles.bodySmall.copyWith(color: GardenColors.ink),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: GardenIcon(asset: GardenIcons.letters, size: 20),
              ),
              hintText: 'Busca: monstera, potos, ficus...',
              hintStyle: GardenTextStyles.bodySmall
                  .copyWith(color: GardenColors.inkSoft),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: GardenColors.creamPaper),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: GardenColors.creamPaper),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: GardenColors.leafDark, width: 1.5),
              ),
            ),
          ),
        ),
        // Lista de resultados
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final plant = filtered[i];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onSelectPlant,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GardenColors.creamPaper),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                              color: GardenColors.creamLight,
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text(plant.emoji,
                                style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plant.name,
                                  style: GardenTextStyles.title.copyWith(
                                      color: GardenColors.ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              Text(plant.species,
                                  style: GardenTextStyles.label.copyWith(
                                      color: GardenColors.inkSoft,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(plant.level,
                            style: GardenTextStyles.label.copyWith(
                                color: GardenColors.inkSoft, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

// ── 3. Resultado identificado ─────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final VoidCallback onAdd;
  const _ResultView({required this.onAdd});

  // Demo hardcoded — TODO(backend): proviene del endpoint de identificación IA
  static const _careItems = [
    (
      GardenIcons.water,
      'AGUA',
      'Cada 7 días, deja secar la capa superior'
    ),
    (GardenIcons.sun, 'LUZ', 'Luz indirecta brillante'),
    (GardenIcons.soil, 'SUSTRATO', 'Mezcla aireada con perlita'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de identificación
          Container(
            decoration: BoxDecoration(
              color: GardenColors.creamLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GardenColors.dustLight, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: GardenColors.ink.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: GardenColors.creamLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                    child: const Center(
                    child: GardenIcon(asset: GardenIcons.plantEco, size: 32),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GardenColors.leafDark.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const GardenIcon(
                                asset: GardenIcons.logroDesbloqueado,
                                size: 12),
                            const SizedBox(width: 4),
                            Text('IDENTIFICADA',
                                style: GardenTextStyles.label.copyWith(
                                    color: GardenColors.leafDark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Monstera',
                          style: GardenTextStyles.title.copyWith(
                              color: GardenColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      Text('Monstera Deliciosa',
                          style: GardenTextStyles.label.copyWith(
                              color: GardenColors.inkSoft, fontSize: 12)),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: GardenTextStyles.bodySmall
                              .copyWith(color: GardenColors.ink, fontSize: 13),
                          children: const [
                            TextSpan(
                                text: 'Origen: ',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(
                                text: 'Bosques tropicales del sur de México'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: GardenTextStyles.bodySmall
                              .copyWith(color: GardenColors.ink, fontSize: 13),
                          children: const [
                            TextSpan(
                                text: 'Dificultad de cuidado: ',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: 'Fácil'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text('Cuidados generales',
              style: GardenTextStyles.title.copyWith(
                  color: GardenColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 12),

          // Lista de cuidados
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GardenColors.creamPaper),
            ),
            child: Column(
              children: _careItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                                color: GardenColors.creamLight,
                                shape: BoxShape.circle),
                            child: GardenIcon(asset: item.$1, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$2,
                                  style: GardenTextStyles.label.copyWith(
                                      color: GardenColors.inkSoft,
                                      fontSize: 10,
                                      letterSpacing: 0.8)),
                              Text(item.$3,
                                  style: GardenTextStyles.bodySmall.copyWith(
                                      color: GardenColors.ink,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (i < _careItems.length - 1)
                      const Divider(
                          height: 1,
                          thickness: 1,
                          color: GardenColors.creamPaper,
                          indent: 16,
                          endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Tip de oro
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GardenColors.creamPaper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GardenColors.creamPaper),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✨', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Concejo jardinero',
                          style: GardenTextStyles.label.copyWith(
                              color: GardenColors.leafDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 2),
                      Text(
                          'Limpia sus hojas con un paño húmedo cada 2 semanas.',
                          style: GardenTextStyles.bodySmall
                              .copyWith(color: GardenColors.ink, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botón agregar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const GardenIcon(asset: GardenIcons.addPlant, size: 18),
              label: const Text('Agregar a mi jardín',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: GardenColors.leafDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4. Matches IA (Slide Cards) ───────────────────────────────────────────────

class _MatchesView extends StatefulWidget {
  final VoidCallback onSelectMatch;
  const _MatchesView({required this.onSelectMatch});

  @override
  State<_MatchesView> createState() => _MatchesViewState();
}

class _MatchesViewState extends State<_MatchesView> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.82);

  static const _matches = [
    (
      name: 'Monstera',
      species: 'Monstera deliciosa',
      pct: 94,
      tags: ['Fácil', 'Interior', 'México'],
      emoji: '🌿'
    ),
    (
      name: 'Philodendron',
      species: 'Philodendron bipinnatifidum',
      pct: 73,
      tags: ['Fácil', 'Interior'],
      emoji: '🍃'
    ),
    (
      name: 'Pothos',
      species: 'Epipremnum aureum',
      pct: 45,
      tags: ['Fácil', 'Interior', 'Baño'],
      emoji: '🌱'
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMatch = _matches[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header info
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GardenColors.leafDark.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_matches.length} POSIBLES COINCIDENCIAS',
                  style: GardenTextStyles.label.copyWith(
                    color: GardenColors.leafDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¿Cuál de estas es tu planta?',
                style: GardenTextStyles.title.copyWith(
                  color: GardenColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona la opción correcta para ver sus cuidados detallados.',
                style: GardenTextStyles.bodySmall.copyWith(
                  color: GardenColors.inkSoft,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Cards list using PageView
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _matches.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final match = _matches[index];
              final isActive = index == _currentIndex;
              
              // Color badge logic
              final Color badgeColor = match.pct >= 80
                  ? GardenColors.leafDark
                  : match.pct >= 60
                      ? GardenColors.potOrange
                      : GardenColors.heartRed;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: isActive ? 16 : 28,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isActive
                        ? GardenColors.leafDark.withOpacity(0.3)
                        : GardenColors.dustLight,
                    width: isActive ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GardenColors.ink.withOpacity(isActive ? 0.12 : 0.04),
                      blurRadius: isActive ? 24 : 12,
                      offset: Offset(0, isActive ? 12 : 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Emoji / Image container
                    Expanded(
                      flex: 5,
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: GardenColors.sageLight,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(22),
                              ),
                            ),
                            child: Center(
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 300),
                                scale: isActive ? 1.15 : 1.0,
                                child: Text(
                                  match.emoji,
                                  style: const TextStyle(fontSize: 84),
                                ),
                              ),
                            ),
                          ),
                          // Percentage badge
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: badgeColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${match.pct}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    'match',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Info area
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.name,
                              style: GardenTextStyles.title.copyWith(
                                color: GardenColors.ink,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              match.species,
                              style: GardenTextStyles.bodySmall.copyWith(
                                color: GardenColors.inkSoft,
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            // Tag chips
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: match.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GardenColors.creamPaper,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: GardenColors.dustLight,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: GardenTextStyles.label.copyWith(
                                      color: GardenColors.inkSoft,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom CTA controls
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onSelectMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GardenColors.leafDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    shadowColor: GardenColors.leafDark.withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GardenIcon(
                          asset: GardenIcons.logroDesbloqueado, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Es la ${currentMatch.name}, confirmar',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GardenIcon(
                      asset: GardenIcons.forward,
                      size: 14,
                      opacity: 0.7),
                  const SizedBox(width: 6),
                  Text(
                    'Desliza para ver más opciones',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: GardenColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
