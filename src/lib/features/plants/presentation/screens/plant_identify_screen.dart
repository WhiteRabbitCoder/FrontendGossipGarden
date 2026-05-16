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

enum _IdentifyStep { idle, uploading, selectCandidate, confirm, creating }

class PlantIdentifyScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final void Function(String plantId)? onPlantCreated;

  const PlantIdentifyScreen({super.key, this.onBack, this.onPlantCreated});

  @override
  ConsumerState<PlantIdentifyScreen> createState() =>
      _PlantIdentifyScreenState();
}

class _PlantIdentifyScreenState extends ConsumerState<PlantIdentifyScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  _IdentifyStep _step = _IdentifyStep.idle;
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  CameraController? _cameraController;
  bool _cameraReady = false;

  File? _imageFile;
  IdentifyCompleted? _completed;
  List<SpeciesCandidate> _candidates = [];
  String? _errorMessage;

  final _nicknameController = TextEditingController();

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
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _scanController.dispose();
    _nicknameController.dispose();
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
    } else if (state == AppLifecycleState.resumed) {
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

  // ─── Capture & identify ───────────────────────────────────────────────────

  Future<void> _captureAndIdentify() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    // Tomar foto y procesar en memoria antes de cambiar step
    final xFile = await controller.takePicture();
    final bytes = await File(xFile.path).readAsBytes();

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

    final file = File(outPath);

    if (!mounted) return;
    setState(() {
      _imageFile = file;
      _step = _IdentifyStep.uploading;
      _errorMessage = null;
    });
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
            _completed = result;
            _nicknameController.text = result.profile.commonName;
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

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final bytes = await File(picked.path).readAsBytes();
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

    final file = File(outPath);
    if (!mounted) return;
    setState(() {
      _imageFile = file;
      _step = _IdentifyStep.uploading;
      _errorMessage = null;
    });
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
            _completed = result;
            _nicknameController.text = result.profile.commonName;
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
      final plant = await createDs.createPlant(
        speciesId: completed.profile.speciesId,
        nickname: nickname,
        photoStoragePath: completed.photoStoragePath,
      );

      ref.invalidate(plantsProvider);

      if (!mounted) return;
      widget.onPlantCreated?.call(plant.id);
      if (widget.onPlantCreated == null) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _IdentifyStep.confirm;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GardenColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GardenColors.forest),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: Text(
          'Identificar planta',
          style: GardenTextStyles.title.copyWith(color: GardenColors.forest),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Expanded(child: _buildStep()),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
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

  // ─── Step: Idle ───────────────────────────────────────────────────────────

  Widget _buildIdle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Viewfinder con preview de cámara embebido
        Container(
          width: double.infinity,
          height: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF1A2E1A),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: GardenColors.forest, width: 3),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(29),
                child: _buildViewfinderContent(),
              ),
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
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
              ),
              ..._viewfinderCorners(),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: GardenColors.errorRose.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: GardenColors.errorRose.withValues(alpha: 0.3)),
            ),
            child: Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: GardenTextStyles.bodySmall
                    .copyWith(color: GardenColors.errorRose)),
          ),

        Text('Enfoca tu planta',
            style: GardenTextStyles.title.copyWith(fontSize: 22)),
        const SizedBox(height: 8),
        Text('Tomaremos una foto para identificarla con IA',
            textAlign: TextAlign.center,
            style: GardenTextStyles.body
                .copyWith(color: GardenColors.earth, fontSize: 15)),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _cameraReady ? _captureAndIdentify : null,
            icon: const Icon(Icons.document_scanner_rounded),
            label: const Text('Identificar',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: GardenColors.forest,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  GardenColors.forest.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Elegir de galería',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: GardenColors.forest,
              side: const BorderSide(color: GardenColors.forest, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ),
      ],
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
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity);
    }
    return Center(
      child: Icon(Icons.local_florist,
          size: 80, color: GardenColors.forest.withValues(alpha: 0.4)),
    );
  }

  // ─── Step: Uploading / Scanning ───────────────────────────────────────────

  Widget _buildUploading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF1A2E1A),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: GardenColors.forest, width: 3),
          ),
          child: Stack(
            children: [
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(29),
                  child: Image.file(_imageFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity),
                )
              else
                Center(
                  child: Icon(Icons.local_florist,
                      size: 80,
                      color: GardenColors.forest.withValues(alpha: 0.4)),
                ),
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (_, __) => Positioned(
                  top: _scanAnimation.value * 240,
                  left: 0, right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        GardenColors.sage.withValues(alpha: 0.8),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
              ..._viewfinderCorners(),
            ],
          ),
        ),
        const SizedBox(height: 40),
        const CircularProgressIndicator(
            color: GardenColors.forest, strokeWidth: 3),
        const SizedBox(height: 20),
        Text('Analizando...',
            style: GardenTextStyles.title.copyWith(fontSize: 18)),
        const SizedBox(height: 6),
        Text('Consultando base de datos botánica',
            style: GardenTextStyles.body
                .copyWith(color: GardenColors.dust, fontSize: 14)),
      ],
    );
  }

  // ─── Step: Select candidate ───────────────────────────────────────────────

  Widget _buildSelectCandidate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿Cuál es tu planta?',
            style: GardenTextStyles.title.copyWith(fontSize: 22)),
        const SizedBox(height: 4),
        Text('Selecciona la que más se parezca',
            style:
                GardenTextStyles.body.copyWith(color: GardenColors.earth)),
        const SizedBox(height: 16),

        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: GardenColors.errorRose.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_errorMessage!,
                style: GardenTextStyles.bodySmall
                    .copyWith(color: GardenColors.errorRose)),
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

        const SizedBox(height: 16),
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
        const SizedBox(height: 8),
      ],
    );
  }

  // ─── Step: Confirm ────────────────────────────────────────────────────────

  Widget _buildConfirm() {
    final profile = _completed!.profile;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GardenColors.sageLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(Icons.verified_rounded,
                    color: GardenColors.forest, size: 32),
                const SizedBox(height: 8),
                Text('¡Identificada!',
                    style: GardenTextStyles.bodySmall
                        .copyWith(color: GardenColors.forest)),
                const SizedBox(height: 4),
                Text(profile.commonName,
                    textAlign: TextAlign.center,
                    style:
                        GardenTextStyles.display.copyWith(fontSize: 28)),
                const SizedBox(height: 2),
                Text(profile.scientificName,
                    textAlign: TextAlign.center,
                    style: GardenTextStyles.body.copyWith(
                        fontStyle: FontStyle.italic,
                        color: GardenColors.forest,
                        fontSize: 15)),
                const SizedBox(height: 8),
                Text(profile.family,
                    style: GardenTextStyles.bodySmall
                        .copyWith(color: GardenColors.earth)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (profile.careSummary.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(profile.careSummary,
                  style: GardenTextStyles.body
                      .copyWith(fontSize: 14, height: 1.5)),
            ),

          const SizedBox(height: 20),

          Text('Ponle un apodo',
              style: GardenTextStyles.title.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              hintText: profile.commonName,
              hintStyle: GardenTextStyles.body
                  .copyWith(color: GardenColors.dust),
              prefixIcon: const Icon(Icons.local_florist,
                  color: GardenColors.moss),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
            style: GardenTextStyles.body,
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GardenColors.errorRose.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_errorMessage!,
                  style: GardenTextStyles.bodySmall
                      .copyWith(color: GardenColors.errorRose)),
            ),
          ],

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _createPlant,
            style: ElevatedButton.styleFrom(
              backgroundColor: GardenColors.forest,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            child: Text('¡Esta es mi planta!',
                style: GardenTextStyles.title
                    .copyWith(color: Colors.white, fontSize: 18)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Step: Creating ───────────────────────────────────────────────────────

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

  // ─── Viewfinder corners ───────────────────────────────────────────────────

  List<Widget> _viewfinderCorners() {
    const color = Color(0xFF8BC34A);
    const size = 24.0;
    const thickness = 3.0;
    return [
      Positioned(
          top: 12,
          left: 12,
          child: _corner(color, size, thickness, top: true, left: true)),
      Positioned(
          top: 12,
          right: 12,
          child:
              _corner(color, size, thickness, top: true, left: false)),
      Positioned(
          bottom: 12,
          left: 12,
          child:
              _corner(color, size, thickness, top: false, left: true)),
      Positioned(
          bottom: 12,
          right: 12,
          child:
              _corner(color, size, thickness, top: false, left: false)),
    ];
  }

  Widget _corner(Color color, double size, double thickness,
      {required bool top, required bool left}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
          painter:
              _CornerPainter(color, thickness, top: top, left: left)),
    );
  }
}

// ─── Candidate card ───────────────────────────────────────────────────────────

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate, required this.onTap});

  final SpeciesCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (candidate.probability * 100).toStringAsFixed(0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: GardenColors.sageLight, width: 1.5),
        ),
        child: Row(
          children: [
            ClipOval(
              child: candidate.imageUrl != null
                  ? Image.network(
                      candidate.imageUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 52,
                        height: 52,
                        color: GardenColors.sageLight,
                        child: const Icon(Icons.local_florist,
                            color: GardenColors.forest, size: 26),
                      ),
                    )
                  : Container(
                      width: 52,
                      height: 52,
                      color: GardenColors.sageLight,
                      child: const Icon(Icons.local_florist,
                          color: GardenColors.forest, size: 26),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
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
                          style: GardenTextStyles.title
                              .copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: GardenColors.forest.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$pct%',
                            style: GardenTextStyles.bodySmall.copyWith(
                                color: GardenColors.forest,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    candidate.scientificName,
                    style: GardenTextStyles.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: GardenColors.earth),
                  ),
                  if (candidate.family != null)
                    Text(
                      candidate.family!,
                      style: GardenTextStyles.bodySmall
                          .copyWith(color: GardenColors.dust),
                    ),
                  if (candidate.description != null &&
                      candidate.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      candidate.description!,
                      style: GardenTextStyles.bodySmall.copyWith(
                          color: GardenColors.earth, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (candidate.referenceImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: candidate.referenceImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            candidate.referenceImages[i],
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: GardenColors.dust),
          ],
        ),
      ),
    );
  }
}

// ─── Candidate page card (carrusel pantalla completa) ─────────────────────────

class _CandidatePageCard extends StatelessWidget {
  const _CandidatePageCard({required this.candidate, required this.onSelect});

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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                            color: GardenColors.forest.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pct%',
                            style: GardenTextStyles.label.copyWith(
                                color: GardenColors.forest,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      candidate.scientificName,
                      style: GardenTextStyles.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: GardenColors.earth),
                    ),
                    if (candidate.family != null)
                      Text(
                        candidate.family!,
                        style: GardenTextStyles.bodySmall
                            .copyWith(color: GardenColors.dust),
                      ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: GardenColors.forest,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: onSelect,
                        child: Text(
                          'Elegir esta',
                          style: GardenTextStyles.body.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
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

// ─── Corner painter ───────────────────────────────────────────────────────────

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
