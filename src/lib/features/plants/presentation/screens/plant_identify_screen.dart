import 'package:flutter/material.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';

// Flujo: método → cámara/búsqueda → resultado identificado → agregar
enum _IdentifyMode { select, camera, search, result }

class PlantIdentifyScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCompleted;

  const PlantIdentifyScreen({super.key, this.onBack, this.onCompleted});

  @override
  State<PlantIdentifyScreen> createState() => _PlantIdentifyScreenState();
}

class _PlantIdentifyScreenState extends State<PlantIdentifyScreen> {
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
    } else {
      setState(() => _mode = _IdentifyMode.select);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GardenColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: GardenColors.charcoal, size: 20),
          onPressed: _back,
        ),
        title: Text(
          'Nueva planta',
          style: GardenTextStyles.title.copyWith(
              color: GardenColors.charcoal, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: GardenColors.dustLight, height: 1),
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
          onIdentified: () => setState(() => _mode = _IdentifyMode.result),
        );
      case _IdentifyMode.search:
        return _SearchView(
          controller: _searchController,
          query: _searchQuery,
          onQueryChanged: (q) => setState(() => _searchQuery = q),
          onSelectPlant: () => setState(() => _mode = _IdentifyMode.result),
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
  const _SelectMethodView(
      {required this.onCamera, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo quieres\nidentificarla?',
            style: GardenTextStyles.display.copyWith(
              color: GardenColors.charcoal,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Elige el método más cómodo para ti.',
            style:
                GardenTextStyles.bodySmall.copyWith(color: GardenColors.dust),
          ),
          const SizedBox(height: 28),
          _MethodCard(
            icon: Icons.camera_alt_outlined,
            title: 'Reconocer con cámara',
            subtitle: 'Toma o sube una foto y la identificamos por ti.',
            badge: 'Recomendado',
            onTap: onCamera,
          ),
          const SizedBox(height: 12),
          _MethodCard(
            icon: Icons.text_fields_rounded,
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
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
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
            border: Border.all(color: GardenColors.dustLight),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                    color: GardenColors.sageLight, shape: BoxShape.circle),
                child: Icon(icon, color: GardenColors.forest, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GardenTextStyles.title.copyWith(
                          color: GardenColors.charcoal,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GardenTextStyles.bodySmall
                          .copyWith(color: GardenColors.dust, fontSize: 13),
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
                                color: GardenColors.forest,
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
      child: Column(
        children: [
          // Placeholder de cámara
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFEEECE8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _scanning
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: GardenColors.forest))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: GardenColors.dust),
                        const SizedBox(height: 10),
                        Text(
                          'Esperando imagen...',
                          style: GardenTextStyles.bodySmall
                              .copyWith(color: GardenColors.dust),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _scanning ? null : _identify,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Abrir cámara',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: GardenColors.forest,
                foregroundColor: Colors.white,
                disabledBackgroundColor: GardenColors.moss,
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

  // Demo hardcoded — TODO(backend): conectar endpoint de catálogo de plantas
  static const _catalog = [
    (emoji: '🌿', name: 'Monstera', species: 'Monstera Deliciosa', level: 'Fácil'),
    (emoji: '🍃', name: 'Potos', species: 'Epipremnum Aureum', level: 'Fácil'),
    (emoji: '🌳', name: 'Ficus Lyrata', species: 'Ficus Lyrata', level: 'Exigente'),
    (emoji: '🌵', name: 'Suculenta Echeveria', species: 'Echeveria Elegans', level: 'Fácil'),
    (emoji: '🪴', name: 'Sansevieria', species: 'Dracaena Trifasciata', level: 'Fácil'),
    (emoji: '🌱', name: 'Calathea', species: 'Calathea Orbifolia', level: 'Exigente'),
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
            style: GardenTextStyles.bodySmall
                .copyWith(color: GardenColors.charcoal),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded,
                  color: GardenColors.dust, size: 20),
              hintText: 'Busca: monstera, potos, ficus...',
              hintStyle: GardenTextStyles.bodySmall
                  .copyWith(color: GardenColors.dust),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: GardenColors.dustLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: GardenColors.dustLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: GardenColors.forest, width: 1.5),
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
                      border: Border.all(color: GardenColors.dustLight),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                              color: GardenColors.sageLight,
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
                                      color: GardenColors.charcoal,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              Text(plant.species,
                                  style: GardenTextStyles.label.copyWith(
                                      color: GardenColors.dust,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(plant.level,
                            style: GardenTextStyles.label.copyWith(
                                color: GardenColors.dust, fontSize: 12)),
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
    (Icons.water_drop_outlined, 'AGUA', 'Cada 7 días, deja secar la capa superior'),
    (Icons.wb_sunny_outlined, 'LUZ', 'Luz indirecta brillante'),
    (Icons.grass_outlined, 'SUSTRATO', 'Mezcla aireada con perlita'),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GardenColors.dustLight),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: GardenColors.sageLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 32)),
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
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 12,
                                color: Color(0xFF2E7D32)),
                            const SizedBox(width: 4),
                            Text('IDENTIFICADA',
                                style: GardenTextStyles.label.copyWith(
                                    color: const Color(0xFF2E7D32),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Monstera',
                          style: GardenTextStyles.title.copyWith(
                              color: GardenColors.charcoal,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      Text('Monstera Deliciosa',
                          style: GardenTextStyles.label.copyWith(
                              color: GardenColors.dust, fontSize: 12)),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: GardenTextStyles.bodySmall.copyWith(
                              color: GardenColors.charcoal, fontSize: 13),
                          children: const [
                            TextSpan(
                                text: 'Origen: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700)),
                            TextSpan(
                                text:
                                    'Bosques tropicales del sur de México'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: GardenTextStyles.bodySmall.copyWith(
                              color: GardenColors.charcoal, fontSize: 13),
                          children: const [
                            TextSpan(
                                text: 'Dificultad: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700)),
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
                  color: GardenColors.charcoal,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 12),

          // Lista de cuidados
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GardenColors.dustLight),
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
                                color: GardenColors.sageLight,
                                shape: BoxShape.circle),
                            child: Icon(item.$1,
                                size: 18, color: GardenColors.forest),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$2,
                                  style: GardenTextStyles.label.copyWith(
                                      color: GardenColors.dust,
                                      fontSize: 10,
                                      letterSpacing: 0.8)),
                              Text(item.$3,
                                  style: GardenTextStyles.bodySmall.copyWith(
                                      color: GardenColors.charcoal,
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
                          color: GardenColors.dustLight,
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
              color: GardenColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GardenColors.dustLight),
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
                      Text('TIP DE ORO',
                          style: GardenTextStyles.label.copyWith(
                              color: GardenColors.forest,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 2),
                      Text(
                          'Limpia sus hojas con un paño húmedo cada 2 semanas.',
                          style: GardenTextStyles.bodySmall.copyWith(
                              color: GardenColors.charcoal, fontSize: 13)),
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
              icon: const Icon(Icons.park_outlined, size: 18),
              label: const Text('Agregar a mi jardín',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: GardenColors.forest,
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
