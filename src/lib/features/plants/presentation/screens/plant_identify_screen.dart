import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../data/models/identification.dart';
import '../providers/plant_providers.dart';

// Flujo: selectMethod → idle (cámara) → uploading → selectCandidate? → confirm → creating
enum _IdentifyStep { selectMethod, idle, uploading, selectCandidate, confirm, creating }

class PlantIdentifyScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCompleted;

  const PlantIdentifyScreen({super.key, this.onBack, this.onCompleted});

  @override
  ConsumerState<PlantIdentifyScreen> createState() => _PlantIdentifyScreenState();
}

class _PlantIdentifyScreenState extends ConsumerState<PlantIdentifyScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  _IdentifyStep _step = _IdentifyStep.selectMethod;
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  CameraController? _cameraController;
  bool _cameraReady = false;

  File? _imageFile;
  IdentifyCompleted? _completed;
  List<SpeciesCandidate> _candidates = [];
  String? _errorMessage;

  final _nicknameController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    _pageController = PageController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _scanController.dispose();
    _nicknameController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _cameraController = null;
      if (mounted) setState(() => _cameraReady = false);
    } else if (state == AppLifecycleState.resumed && _step == _IdentifyStep.idle) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty || !mounted) return;

    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    if (!mounted) return;

    setState(() {
      _cameraController = controller;
      _cameraReady = true;
    });
  }

  // ─── Navegación ──────────────────────────────────────────────────────────────

  void _onBack() {
    switch (_step) {
      case _IdentifyStep.selectMethod:
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          Navigator.maybePop(context);
        }
      case _IdentifyStep.idle:
        _cameraController?.dispose();
        _cameraController = null;
        setState(() {
          _cameraReady = false;
          _step = _IdentifyStep.selectMethod;
          _errorMessage = null;
        });
      case _IdentifyStep.selectCandidate:
      case _IdentifyStep.confirm:
        _cameraController?.dispose();
        _cameraController = null;
        setState(() {
          _cameraReady = false;
          _step = _IdentifyStep.selectMethod;
          _imageFile = null;
          _completed = null;
          _candidates = [];
          _errorMessage = null;
        });
      case _IdentifyStep.uploading:
      case _IdentifyStep.creating:
        break; // no back durante operaciones asíncronas
    }
  }

  void _goToCamera() {
    setState(() {
      _step = _IdentifyStep.idle;
      _errorMessage = null;
    });
    _initCamera();
  }

  // ─── Captura y pipeline de identificación ────────────────────────────────────

  Future<void> _captureAndIdentify() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final xFile = await controller.takePicture();
    final file = await _processImage(xFile.path);
    if (!mounted) return;

    setState(() {
      _imageFile = file;
      _step = _IdentifyStep.uploading;
      _errorMessage = null;
    });
    await _runIdentify(file);
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final file = await _processImage(picked.path);
    if (!mounted) return;

    setState(() {
      _imageFile = file;
      _step = _IdentifyStep.uploading;
      _errorMessage = null;
    });
    await _runIdentify(file);
  }

  Future<File> _processImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final original = img.decodeImage(bytes)!;
    final oriented = img.bakeOrientation(original);

    final w = oriented.width;
    final h = oriented.height;
    final side = w < h ? w : h;

    final cropped = img.copyCrop(
      oriented,
      x: (w - side) ~/ 2,
      y: (h - side) ~/ 2,
      width: side,
      height: side,
    );
    final resized = img.copyResize(cropped, width: 1024, height: 1024);

    final outPath =
        '${Directory.systemTemp.path}/plant_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outPath).writeAsBytes(img.encodeJpg(resized, quality: 92));
    return File(outPath);
  }

  Future<void> _runIdentify(File file) async {
    _scanController.repeat(reverse: true);

    try {
      final datasource = ref.read(identificationApiDatasourceProvider);
      final result = await datasource.identify(image: file);

      _scanController.stop();
      if (!mounted) return;

      switch (result) {
        case NeedsMorePhotos(:final reason):
          setState(() {
            _step = _IdentifyStep.idle;
            _errorMessage = reason;
          });
          _showNeedsMorePhotosDialog(reason);

        case NeedsUserSelection(:final candidates):
          setState(() {
            _step = _IdentifyStep.selectCandidate;
            _candidates = candidates;
          });

        case IdentifyCompleted():
          setState(() {
            _completed = result as IdentifyCompleted;
            _nicknameController.text = _completed!.profile.commonName;
            _step = _IdentifyStep.confirm;
          });
      }
    } catch (e) {
      _scanController.stop();
      if (mounted) {
        setState(() {
          _step = _IdentifyStep.idle;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _selectCandidate(SpeciesCandidate candidate) async {
    setState(() {
      _step = _IdentifyStep.uploading;
      _errorMessage = null;
    });
    _scanController.repeat(reverse: true);

    try {
      final datasource = ref.read(identificationApiDatasourceProvider);
      final result = await datasource.fromCandidate(candidate: candidate);
      _scanController.stop();
      if (!mounted) return;
      setState(() {
        _completed = result;
        _nicknameController.text = result.profile.commonName;
        _step = _IdentifyStep.confirm;
      });
    } catch (e) {
      _scanController.stop();
      if (mounted) {
        setState(() {
          _step = _IdentifyStep.selectCandidate;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _createPlant() async {
    final completed = _completed;
    if (completed == null) return;

    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    setState(() => _step = _IdentifyStep.creating);

    try {
      final createDs = ref.read(plantCreateDatasourceProvider);
      await createDs.createPlant(
        speciesId: completed.profile.speciesId,
        nickname: nickname,
        photoStoragePath: completed.photoStoragePath,
      );

      ref.invalidate(plantsProvider);

      if (!mounted) return;
      if (widget.onCompleted != null) {
        widget.onCompleted!();
      } else {
        Navigator.maybePop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _IdentifyStep.confirm;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // ─── Diálogos ─────────────────────────────────────────────────────────────────

  void _showNeedsMorePhotosDialog(String reason) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Foto insuficiente'),
        content: Text(reason.isNotEmpty
            ? reason
            : 'No pudimos identificar la planta. Intenta con mejor iluminación o acércate más.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

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
          onPressed: _onBack,
        ),
        title: Text(
          _appBarTitle,
          style: GardenTextStyles.title.copyWith(
              color: GardenColors.charcoal, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: GardenColors.dustLight, height: 1),
        ),
      ),
      body: _buildStep(),
    );
  }

  String get _appBarTitle {
    switch (_step) {
      case _IdentifyStep.selectMethod:
        return 'Nueva planta';
      case _IdentifyStep.idle:
      case _IdentifyStep.uploading:
        return 'Identificar planta';
      case _IdentifyStep.selectCandidate:
        return '¿Cuál es tu planta?';
      case _IdentifyStep.confirm:
        return 'Planta encontrada';
      case _IdentifyStep.creating:
        return 'Guardando...';
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case _IdentifyStep.selectMethod:
        return _SelectMethodView(
          onCamera: _goToCamera,
          onSearch: () => setState(() => _step = _IdentifyStep.selectMethod),
          // Search se queda en la misma pantalla pero con la lista visible
          onSearchDirect: () {},
        );
      case _IdentifyStep.idle:
        return _buildIdle();
      case _IdentifyStep.uploading:
        return _buildUploading();
      case _IdentifyStep.selectCandidate:
        return _buildSelectCandidate();
      case _IdentifyStep.confirm:
        return _buildConfirm();
      case _IdentifyStep.creating:
        return _buildCreating();
    }
  }

  // ─── Paso: Seleccionar método ─────────────────────────────────────────────────
  // (delegado al widget stateless _SelectMethodView)

  // ─── Paso: Cámara (idle) ──────────────────────────────────────────────────────

  Widget _buildIdle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        children: [
          // Viewfinder con preview de cámara embebido
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2E1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GardenColors.forest, width: 2),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildViewfinderContent(),
                  ),
                  if (_cameraReady)
                    Positioned(
                      bottom: 16, left: 0, right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Apunta a tu planta',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ),
                      ),
                    ),
                  ..._viewfinderCorners(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: GardenTextStyles.bodySmall
                      .copyWith(color: Colors.redAccent, fontSize: 13)),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cameraReady ? _captureAndIdentify : null,
              icon: const Icon(Icons.document_scanner_rounded, size: 18),
              label: const Text('Identificar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Elegir de galería',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: GardenColors.forest,
                side: const BorderSide(color: GardenColors.forest, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinderContent() {
    final controller = _cameraController;
    if (_cameraReady && controller != null) {
      final previewSize = controller.value.previewSize!;
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      );
    }
    if (_imageFile != null) {
      return Image.file(_imageFile!,
          fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_florist,
              size: 64, color: GardenColors.forest.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('Iniciando cámara...',
              style: GardenTextStyles.bodySmall
                  .copyWith(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  // ─── Paso: Subiendo / Analizando ─────────────────────────────────────────────

  Widget _buildUploading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2E1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GardenColors.forest, width: 2),
              ),
              child: Stack(
                children: [
                  if (_imageFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(_imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity),
                    )
                  else
                    Center(
                      child: Icon(Icons.local_florist,
                          size: 64,
                          color: GardenColors.forest.withValues(alpha: 0.4)),
                    ),
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (_, __) {
                      return LayoutBuilder(
                        builder: (ctx, constraints) => Positioned(
                          top: _scanAnimation.value * (constraints.maxHeight - 4),
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                GardenColors.sage.withValues(alpha: 0.9),
                                Colors.transparent,
                              ]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  ..._viewfinderCorners(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
              color: GardenColors.forest, strokeWidth: 3),
          const SizedBox(height: 16),
          Text('Analizando...',
              style: GardenTextStyles.title.copyWith(
                  color: GardenColors.charcoal,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 6),
          Text('Consultando base de datos botánica',
              style: GardenTextStyles.bodySmall
                  .copyWith(color: GardenColors.dust, fontSize: 13)),
        ],
      ),
    );
  }

  // ─── Paso: Seleccionar candidato ─────────────────────────────────────────────

  Widget _buildSelectCandidate() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Encontramos varias opciones',
              style: GardenTextStyles.bodySmall
                  .copyWith(color: GardenColors.dust, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Desliza y elige la que más se parezca',
              style: GardenTextStyles.title.copyWith(
                  color: GardenColors.charcoal,
                  fontWeight: FontWeight.w700,
                  fontSize: 20)),
          const SizedBox(height: 16),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_errorMessage!,
                  style: GardenTextStyles.bodySmall
                      .copyWith(color: Colors.redAccent)),
            ),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _candidates.length,
              itemBuilder: (_, i) => _CandidatePageCard(
                candidate: _candidates[i],
                onSelect: () => _selectCandidate(_candidates[i]),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _candidates.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? GardenColors.forest
                      : GardenColors.sageLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Paso: Confirmar ──────────────────────────────────────────────────────────

  Widget _buildConfirm() {
    final profile = _completed!.profile;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : const Center(
                          child: Text('🌿', style: TextStyle(fontSize: 32))),
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
                                size: 12, color: Color(0xFF2E7D32)),
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
                      Text(profile.commonName,
                          style: GardenTextStyles.title.copyWith(
                              color: GardenColors.charcoal,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      Text(profile.scientificName,
                          style: GardenTextStyles.label.copyWith(
                              color: GardenColors.dust,
                              fontStyle: FontStyle.italic,
                              fontSize: 12)),
                      if (profile.family.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: GardenTextStyles.bodySmall.copyWith(
                                color: GardenColors.charcoal, fontSize: 13),
                            children: [
                              const TextSpan(
                                  text: 'Familia: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700)),
                              TextSpan(text: profile.family),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (profile.careTips.isNotEmpty) ...[
            Text('Cuidados generales',
                style: GardenTextStyles.title.copyWith(
                    color: GardenColors.charcoal,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: GardenColors.dustLight),
              ),
              child: Column(
                children: profile.careTips.take(3).toList().asMap().entries.map((e) {
                  final i = e.key;
                  final tip = e.value;
                  const icons = [
                    Icons.water_drop_outlined,
                    Icons.wb_sunny_outlined,
                    Icons.grass_outlined,
                  ];
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
                              child: Icon(icons[i % icons.length],
                                  size: 18, color: GardenColors.forest),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(tip,
                                  style: GardenTextStyles.bodySmall.copyWith(
                                      color: GardenColors.charcoal,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      if (i < (profile.careTips.length - 1).clamp(0, 2))
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
          ],

          if (profile.funFacts.isNotEmpty) ...[
            const SizedBox(height: 12),
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
                        Text(profile.funFacts.first,
                            style: GardenTextStyles.bodySmall.copyWith(
                                color: GardenColors.charcoal, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Campo de apodo
          Text('Ponle un apodo',
              style: GardenTextStyles.title.copyWith(
                  color: GardenColors.charcoal,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            style: GardenTextStyles.bodySmall
                .copyWith(color: GardenColors.charcoal),
            decoration: InputDecoration(
              hintText: profile.commonName,
              hintStyle:
                  GardenTextStyles.bodySmall.copyWith(color: GardenColors.dust),
              prefixIcon: const Icon(Icons.local_florist,
                  color: GardenColors.moss, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                borderSide: const BorderSide(
                    color: GardenColors.forest, width: 1.5),
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_errorMessage!,
                  style: GardenTextStyles.bodySmall
                      .copyWith(color: Colors.redAccent)),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createPlant,
              icon: const Icon(Icons.park_outlined, size: 18),
              label: const Text('Agregar a mi jardín',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

  // ─── Paso: Creando ────────────────────────────────────────────────────────────

  Widget _buildCreating() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              color: GardenColors.forest, strokeWidth: 3),
          SizedBox(height: 20),
          Text('Registrando tu planta...'),
        ],
      ),
    );
  }

  // ─── Corners del visor ────────────────────────────────────────────────────────

  List<Widget> _viewfinderCorners() {
    const color = Color(0xFF8BC34A);
    const size = 22.0;
    const thickness = 2.5;
    return [
      Positioned(
          top: 10, left: 10,
          child: _corner(color, size, thickness, top: true, left: true)),
      Positioned(
          top: 10, right: 10,
          child: _corner(color, size, thickness, top: true, left: false)),
      Positioned(
          bottom: 10, left: 10,
          child: _corner(color, size, thickness, top: false, left: true)),
      Positioned(
          bottom: 10, right: 10,
          child: _corner(color, size, thickness, top: false, left: false)),
    ];
  }

  Widget _corner(Color color, double size, double thickness,
      {required bool top, required bool left}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
          painter: _CornerPainter(color, thickness, top: top, left: left)),
    );
  }
}

// ── Seleccionar método (UI de views) ─────────────────────────────────────────

class _SelectMethodView extends StatefulWidget {
  final VoidCallback onCamera;
  final VoidCallback onSearch;
  final VoidCallback onSearchDirect;

  const _SelectMethodView({
    required this.onCamera,
    required this.onSearch,
    required this.onSearchDirect,
  });

  @override
  State<_SelectMethodView> createState() => _SelectMethodViewState();
}

class _SelectMethodViewState extends State<_SelectMethodView> {
  bool _showSearch = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Demo hardcoded — no hay endpoint de búsqueda en el backend aún
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
    if (_showSearch) return _buildSearchView();
    return _buildSelectView();
  }

  Widget _buildSelectView() {
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
            style: GardenTextStyles.bodySmall
                .copyWith(color: GardenColors.dust),
          ),
          const SizedBox(height: 28),
          _MethodCard(
            icon: Icons.camera_alt_outlined,
            title: 'Reconocer con cámara',
            subtitle: 'Toma o sube una foto y la identificamos por ti.',
            badge: 'Recomendado',
            onTap: widget.onCamera,
          ),
          const SizedBox(height: 12),
          _MethodCard(
            icon: Icons.text_fields_rounded,
            title: 'Buscar por nombre',
            subtitle: 'Si ya sabes qué planta es, búscala en el catálogo.',
            onTap: () => setState(() => _showSearch = true),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchView() {
    final filtered = _catalog
        .where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.species.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (q) => setState(() => _searchQuery = q),
            style: GardenTextStyles.bodySmall
                .copyWith(color: GardenColors.charcoal),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded,
                  color: GardenColors.dust, size: 20),
              hintText: 'Busca: monstera, potos, ficus...',
              hintStyle:
                  GardenTextStyles.bodySmall.copyWith(color: GardenColors.dust),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: GardenColors.dustLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: GardenColors.dustLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: GardenColors.forest, width: 1.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding:
                const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final plant = filtered[i];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Búsqueda por nombre próximamente. Usa la cámara para identificar.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: GardenColors.dustLight),
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
                                style:
                                    const TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(plant.name,
                                  style: GardenTextStyles.title
                                      .copyWith(
                                          color: GardenColors.charcoal,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                              Text(plant.species,
                                  style: GardenTextStyles.label
                                      .copyWith(
                                          color: GardenColors.dust,
                                          fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(plant.level,
                            style: GardenTextStyles.label.copyWith(
                                color: GardenColors.dust,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
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
                    Text(title,
                        style: GardenTextStyles.title.copyWith(
                            color: GardenColors.charcoal,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: GardenTextStyles.bodySmall.copyWith(
                            color: GardenColors.dust, fontSize: 13)),
                    if (badge != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(badge!,
                              style: GardenTextStyles.label.copyWith(
                                  color: GardenColors.forest,
                                  fontWeight: FontWeight.w700)),
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

// ── Tarjeta de candidato (carrusel) ──────────────────────────────────────────

class _CandidatePageCard extends StatelessWidget {
  const _CandidatePageCard(
      {required this.candidate, required this.onSelect});

  final SpeciesCandidate candidate;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final pct = (candidate.probability * 100).toStringAsFixed(0);
    final imageUrl = candidate.imageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2/3 — imagen de referencia
            Expanded(
              flex: 2,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: GardenColors.sageLight,
                        child: const Center(
                          child: Icon(Icons.local_florist,
                              size: 64, color: GardenColors.forest),
                        ),
                      ),
                    )
                  : Container(
                      color: GardenColors.sageLight,
                      child: const Center(
                        child: Icon(Icons.local_florist,
                            size: 64, color: GardenColors.forest),
                      ),
                    ),
            ),
            // 1/3 — texto + botón
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            candidate.commonNames.isNotEmpty
                                ? candidate.commonNames.first
                                : candidate.scientificName,
                            style: GardenTextStyles.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: GardenColors.forest
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Text('$pct%',
                              style: GardenTextStyles.label.copyWith(
                                  color: GardenColors.forest,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(candidate.scientificName,
                        style: GardenTextStyles.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                            color: GardenColors.earth)),
                    if (candidate.family != null)
                      Text(candidate.family!,
                          style: GardenTextStyles.bodySmall
                              .copyWith(color: GardenColors.dust)),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GardenColors.forest,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: onSelect,
                        child: Text('Elegir esta',
                            style: GardenTextStyles.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Painter para las esquinas del visor ──────────────────────────────────────

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool top;
  final bool left;

  _CornerPainter(this.color, this.thickness,
      {required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
