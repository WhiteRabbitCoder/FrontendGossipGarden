import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';
import '../../data/models/identification_dto.dart';
import '../../../../core/services/api_client.dart';
import 'package:dio/dio.dart';
import '../providers/plant_providers.dart';
import '../providers/achievement_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Flujo: método → cámara/búsqueda → resultado identificado → agregar
enum _IdentifyMode { select, camera, search, uploading, matches, generating, result, creating }

// HARDCODE(demo): cámara, catálogo, matches y resultado sin API de identificación.
// TODO(backend): POST /plants/identify (imagen/texto) y POST /plants al confirmar.
class PlantIdentifyScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCompleted;

  const PlantIdentifyScreen({super.key, this.onBack, this.onCompleted});

  @override
  ConsumerState<PlantIdentifyScreen> createState() => _PlantIdentifyScreenState();
}

class _PlantIdentifyScreenState extends ConsumerState<PlantIdentifyScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  _IdentifyMode _mode = _IdentifyMode.select;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  CameraController? _cameraController;
  bool _cameraReady = false;
  File? _imageFile;
  IdentifyResponse? _completed;
  List<PlantCandidate> _candidates = [];
  String? _errorMessage;
  String? _photoStoragePath;
  final _nicknameController = TextEditingController();

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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _scanController.dispose();
    _nicknameController.dispose();
    _searchController.dispose();
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
    } else if (state == AppLifecycleState.resumed && _mode == _IdentifyMode.camera) {
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

  void _back() {
    if (_mode == _IdentifyMode.select) {
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.pop(context);
      }
    } else if (_mode == _IdentifyMode.matches || _mode == _IdentifyMode.result) {
      setState(() {
        _cameraController?.dispose();
        _cameraController = null;
        _cameraReady = false;
        _imageFile = null;
        _completed = null;
        _candidates = [];
        _errorMessage = null;
        _photoStoragePath = null;
        _mode = _IdentifyMode.select;
      });
    } else if (_mode == _IdentifyMode.camera || _mode == _IdentifyMode.search) {
      setState(() {
        _cameraController?.dispose();
        _cameraController = null;
        _cameraReady = false;
        _mode = _IdentifyMode.select;
        _errorMessage = null;
      });
    }
    // No action during uploading or creating
  }

  Future<void> _captureAndIdentify() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final xFile = await controller.takePicture();
    final file = await _processImage(xFile.path);
    if (!mounted) return;
    setState(() {
      _imageFile = file;
      _mode = _IdentifyMode.uploading;
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
      _mode = _IdentifyMode.uploading;
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
    final cropped = img.copyCrop(oriented, x: (w - side) ~/ 2, y: (h - side) ~/ 2, width: side, height: side);
    final resized = img.copyResize(cropped, width: 1024, height: 1024);
    final outPath = '${Directory.systemTemp.path}/plant_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outPath).writeAsBytes(img.encodeJpg(resized, quality: 92));
    return File(outPath);
  }

  Future<void> _runIdentify(File file) async {
    _scanController.repeat(reverse: true);
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          filename: 'scan.jpg',
        ),
      });

      final response = await ApiClient().dio.post(
        '/identify',
        data: formData,
      );

      final result = IdentifyResponse.fromJson(response.data);
      _scanController.stop();
      if (!mounted) return;
      
      if (result.status == 'needs_more_photos') {
        setState(() {
          _mode = _IdentifyMode.camera;
          _errorMessage = result.reason ?? 'Intenta con otro ángulo';
        });
        _showNeedsMorePhotosDialog(result.reason ?? 'Intenta con otro ángulo');
      } else if (result.status == 'needs_user_selection') {
        setState(() {
          _mode = _IdentifyMode.matches;
          _candidates = result.candidates ?? [];
          _photoStoragePath = result.photoStoragePath;
        });
      } else if (result.status == 'completed') {
        setState(() {
          _completed = result;
          _photoStoragePath = result.photoStoragePath;
          _nicknameController.text = result.profile?.commonName ?? result.profile?.scientificName ?? '';
          _mode = _IdentifyMode.result;
        });
      }
    } catch (e) {
      _scanController.stop();
      if (mounted) {
        setState(() {
          _mode = _IdentifyMode.camera;
          _errorMessage = _getFriendlyErrorMessage(e);
        });
      }
    }
  }

  Future<void> _selectCandidate(PlantCandidate candidate) async {
    setState(() {
      _mode = _IdentifyMode.generating;
      _errorMessage = null;
    });
    final language = ref.read(authStateProvider).value?.profile?.preferredLanguage ?? 'es';
    try {
      final response = await ApiClient().dio.post(
        '/species/from-candidate',
        data: {
          'candidate': {
            'scientific_name': candidate.scientificName,
            'common_names': candidate.commonNames,
            'probability': candidate.probability,
            'gbif_id': candidate.gbifId,
            'inaturalist_id': candidate.inaturalistId,
            'taxonomy': candidate.taxonomy,
          },
          'output_language': language,
        },
      );
      final result = IdentifyResponse.fromJson(response.data);
      _scanController.stop();
      if (!mounted) return;
      if (result.status == 'completed') {
        setState(() {
          _completed = result;
          _nicknameController.text = result.profile?.commonName ?? result.profile?.scientificName ?? '';
          _mode = _IdentifyMode.result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mode = _IdentifyMode.matches;
          _errorMessage = _getFriendlyErrorMessage(e);
        });
      }
    }
  }

  Future<void> _createPlant() async {
    final completed = _completed;
    if (completed == null) return;
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;
    setState(() => _mode = _IdentifyMode.creating);
    try {
      await ApiClient().dio.post(
        '/plants/',
        data: {
          'species_id': completed.profile?.speciesId,
          'nickname': nickname,
          'photo_storage_path': _photoStoragePath ?? completed.photoStoragePath,
        },
      );
      ref.invalidate(plantsProvider);
      if (!mounted) return;
      if (widget.onCompleted != null) {
        widget.onCompleted!();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mode = _IdentifyMode.result;
          _errorMessage = _getFriendlyErrorMessage(e);
        });
      }
    }
  }

  String _getFriendlyErrorMessage(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout || 
          e.type == DioExceptionType.sendTimeout) {
        return 'La conexión tardó demasiado. Revisa tu internet e intenta de nuevo.';
      } else if (e.type == DioExceptionType.connectionError) {
        return 'No hay conexión a internet. Revisa tu red.';
      } else if (e.response != null) {
        final statusCode = e.response!.statusCode;
        if (statusCode == 500 || statusCode == 502) {
          return 'El servidor está experimentando problemas. Por favor, intenta de nuevo más tarde.';
        } else if (statusCode == 503) {
          return 'Servicio temporalmente saturado. Dale unos segundos y reintenta.';
        } else if (statusCode == 413) {
          return 'La imagen es demasiado pesada. Intenta con una foto de menor resolución.';
        } else if (statusCode == 415) {
          return 'Formato de imagen no soportado. Usa JPEG, PNG o WebP.';
        } else if (statusCode == 422) {
          return 'Error procesando la imagen. Asegúrate de enfocar bien la planta.';
        } else {
          return 'Ha ocurrido un error inesperado ($statusCode).';
        }
      }
    }
    return 'Ocurrió un error inesperado. Vuelve a intentarlo.';
  }

  void _showNeedsMorePhotosDialog(String reason) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Foto insuficiente'),
        content: Text(reason.isNotEmpty ? reason : 'No pudimos identificar la planta. Intenta con mejor iluminación o acércate más.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Reintentar')),
        ],
      ),
    );
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
          _appBarTitle,
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

  String get _appBarTitle {
    switch (_mode) {
      case _IdentifyMode.select: return 'Nueva planta';
      case _IdentifyMode.camera: return 'Identificar planta';
      case _IdentifyMode.uploading: return 'Analizando...';
      case _IdentifyMode.matches: return 'Elige una opción';
      case _IdentifyMode.search: return 'Buscar planta';
      case _IdentifyMode.generating: return 'Consultando IA...';
      case _IdentifyMode.result: return 'Confirmar planta';
      case _IdentifyMode.creating: return 'Guardando...';
    }
  }

  Widget _buildContent() {
    switch (_mode) {
      case _IdentifyMode.select:
        return _SelectMethodView(
          onCamera: () {
            setState(() {
              _mode = _IdentifyMode.camera;
              _errorMessage = null;
            });
            _initCamera();
          },
          onSearch: () => setState(() => _mode = _IdentifyMode.search),
        );
      case _IdentifyMode.camera:
        return _CameraView(
          cameraController: _cameraController,
          cameraReady: _cameraReady,
          errorMessage: _errorMessage,
          onIdentify: _captureAndIdentify,
          onGallery: _pickFromGallery,
        );
      case _IdentifyMode.uploading:
        return _UploadingView(
          imageFile: _imageFile,
          scanAnimation: _scanAnimation,
        );
      case _IdentifyMode.matches:
        return _MatchesView(
          candidates: _candidates,
          errorMessage: _errorMessage,
          onSelectMatch: _selectCandidate,
          onCancel: () => setState(() {
            _mode = _IdentifyMode.camera;
            _errorMessage = null;
          }),
        );
      case _IdentifyMode.search:
        return _SearchView(
          onSelectPlant: (candidate) {
            ref.read(achievementStatsProvider.notifier).recordIdentification();
            _selectCandidate(candidate);
          },
        );
      case _IdentifyMode.generating:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: GardenColors.leafDark),
              SizedBox(height: 16),
              Text('Consultando a la IA experta...', style: TextStyle(color: GardenColors.inkSoft)),
            ],
          ),
        );
      case _IdentifyMode.result:
        return _ResultView(
          completed: _completed,
          imageFile: _imageFile,
          nicknameController: _nicknameController,
          errorMessage: _errorMessage,
          onAdd: _createPlant,
        );
      case _IdentifyMode.creating:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: GardenColors.leafDark),
              SizedBox(height: 16),
              Text('Guardando tu planta...', style: TextStyle(color: GardenColors.inkSoft)),
            ],
          ),
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

class _CameraView extends StatelessWidget {
  final CameraController? cameraController;
  final bool cameraReady;
  final String? errorMessage;
  final VoidCallback onIdentify;
  final VoidCallback onGallery;

  const _CameraView({
    required this.cameraController,
    required this.cameraReady,
    this.errorMessage,
    required this.onIdentify,
    required this.onGallery,
  });

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
                color: const Color(0xFF1A2E1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GardenColors.forest, width: 2),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: cameraReady && cameraController != null
                        ? SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: cameraController!.value.previewSize?.height ?? 1,
                                height: cameraController!.value.previewSize?.width ?? 1,
                                child: CameraPreview(cameraController!),
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const GardenIcon(
                                    asset: GardenIcons.camera,
                                    size: 48,
                                    opacity: 0.6),
                                const SizedBox(height: 10),
                                Text(
                                  'Iniciando cámara...',
                                  style: GardenTextStyles.bodySmall
                                      .copyWith(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                  ),
                  if (cameraReady)
                    Positioned(
                      bottom: 16, left: 0, right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            const SizedBox(height: 20),

            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                ),
                child: Text(errorMessage!,
                    textAlign: TextAlign.center,
                    style: GardenTextStyles.bodySmall
                        .copyWith(color: Colors.redAccent, fontSize: 13)),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: cameraReady ? onIdentify : null,
                icon: const GardenIcon(asset: GardenIcons.camera, size: 18),
                label: const Text('Identificar',
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onGallery,
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
      ),
    );
  }
}

class _UploadingView extends StatelessWidget {
  final File? imageFile;
  final Animation<double> scanAnimation;
  const _UploadingView({required this.imageFile, required this.scanAnimation});

  @override
  Widget build(BuildContext context) {
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
                  if (imageFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(imageFile!,
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
                    animation: scanAnimation,
                    builder: (_, __) {
                      return LayoutBuilder(
                        builder: (ctx, constraints) => Positioned(
                          top: scanAnimation.value * (constraints.maxHeight - 4),
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
          const CircularProgressIndicator(color: GardenColors.forest, strokeWidth: 3),
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
}

List<Widget> _viewfinderCorners() {
  const color = GardenColors.forest;
  const thickness = 3.0;
  return [
    Positioned(top: 16, left: 16, child: SizedBox(width: 40, height: 40, child: CustomPaint(painter: _CornerPainter(color, thickness, top: true, left: true)))),
    Positioned(top: 16, right: 16, child: SizedBox(width: 40, height: 40, child: CustomPaint(painter: _CornerPainter(color, thickness, top: true, left: false)))),
    Positioned(bottom: 16, left: 16, child: SizedBox(width: 40, height: 40, child: CustomPaint(painter: _CornerPainter(color, thickness, top: false, left: true)))),
    Positioned(bottom: 16, right: 16, child: SizedBox(width: 40, height: 40, child: CustomPaint(painter: _CornerPainter(color, thickness, top: false, left: false)))),
  ];
}

// ── 2b. Búsqueda por nombre ───────────────────────────────────────────────────

class _SearchView extends StatefulWidget {
  final ValueChanged<PlantCandidate> onSelectPlant;

  const _SearchView({
    required this.onSelectPlant,
  });

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _controller = TextEditingController();
  List<PlantCandidate> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().dio.get(
        '/species/search',
        queryParameters: {'q': query},
      );
      final list = (response.data as List).map((json) => PlantCandidate.fromJson(json)).toList();
      if (mounted) {
        setState(() {
          _results = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: TextField(
            controller: _controller,
            onChanged: _onSearchChanged,
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: GardenColors.leafDark))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final plant = _results[i];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => widget.onSelectPlant(plant),
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
                                child: const Center(
                                  child: Text('🪴',
                                      style: TextStyle(fontSize: 20)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        plant.commonNames.isNotEmpty
                                            ? plant.commonNames.first
                                            : plant.scientificName,
                                        style: GardenTextStyles.title.copyWith(
                                            color: GardenColors.ink,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700)),
                                    Text(plant.scientificName,
                                        style: GardenTextStyles.label.copyWith(
                                            color: GardenColors.inkSoft,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: GardenColors.inkSoft),
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
  final IdentifyResponse? completed;
  final File? imageFile;
  final TextEditingController nicknameController;
  final String? errorMessage;
  final VoidCallback onAdd;

  const _ResultView({
    required this.completed,
    required this.imageFile,
    required this.nicknameController,
    this.errorMessage,
    required this.onAdd,
  });

  // HARDCODE(demo): iconos para los tips de cuidado devueltos por el backend
  static const _careIcons = [
    GardenIcons.water,
    GardenIcons.sun,
    GardenIcons.soil,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── NUEVO PROTAGONISTA: EL NOMBRE ──
          Text(
            '¡Es una ${completed?.profile?.commonName ?? 'planta hermosa'}!',
            style: GardenTextStyles.display.copyWith(
              color: GardenColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 24,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¿Cómo la vas a llamar? Ponle un apodo para tu jardín.',
            style: GardenTextStyles.bodySmall.copyWith(
              color: GardenColors.inkSoft,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: nicknameController,
            style: GardenTextStyles.title.copyWith(
              color: GardenColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
            decoration: InputDecoration(
              hintText: 'Ej. Señor Ficus',
              hintStyle: GardenTextStyles.title.copyWith(
                color: GardenColors.dust,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: GardenColors.dustLight, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: GardenColors.dustLight, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: GardenColors.leafDark, width: 3),
              ),
            ),
          ),

          if (errorMessage != null)
             Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
             ),
             
          const SizedBox(height: 32),

          // ── INFO BOTÁNICA ──
          Text(
            'Ficha botánica',
            style: GardenTextStyles.title.copyWith(
              color: GardenColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          
          // Tarjeta de identificación
          Container(
            decoration: BoxDecoration(
              color: GardenColors.creamLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: GardenColors.ink.withOpacity(0.1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: GardenColors.ink.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: GardenColors.creamPaper,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(imageFile!, fit: BoxFit.cover),
                        )
                      : const Center(
                          child: GardenIcon(asset: GardenIcons.plantEco, size: 36),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: GardenColors.leafDark.withOpacity(0.1),
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
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(completed?.profile?.scientificName ?? 'Especie desconocida',
                          style: GardenTextStyles.title.copyWith(
                              color: GardenColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GardenTextStyles.bodySmall
                              .copyWith(color: GardenColors.inkSoft, fontSize: 13),
                          children: [
                            const TextSpan(
                                text: 'Familia: ',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: completed?.profile?.family ?? 'Desconocida'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

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
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GardenColors.ink.withOpacity(0.08), width: 1.5),
            ),
            child: Column(
              children: (completed?.profile?.careTips ?? []).take(3).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final tip = entry.value;
                final icon = _careIcons[i % _careIcons.length];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                                color: GardenColors.creamLight,
                                shape: BoxShape.circle),
                            child: GardenIcon(asset: icon, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TIP DE CUIDADO',
                                    style: GardenTextStyles.label.copyWith(
                                        color: GardenColors.inkSoft.withOpacity(0.7),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8)),
                                const SizedBox(height: 2),
                                Text(tip,
                                    style: GardenTextStyles.bodySmall.copyWith(
                                        color: GardenColors.ink,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < 2 && i < (completed?.profile?.careTips.length ?? 0) - 1)
                      Divider(
                          height: 1,
                          thickness: 1,
                          color: GardenColors.ink.withOpacity(0.05),
                          indent: 16,
                          endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Tip de oro
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GardenColors.potOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GardenColors.potOrange.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✨', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Consejo jardinero',
                          style: GardenTextStyles.label.copyWith(
                              color: GardenColors.potOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      Text(
                          'Limpia sus hojas con un paño húmedo cada 2 semanas.',
                          style: GardenTextStyles.bodySmall
                              .copyWith(color: GardenColors.ink, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Botón agregar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const GardenIcon(asset: GardenIcons.addPlant, size: 20),
              label: const Text('Guardar en mi jardín',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: GardenColors.leafDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
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
  final List<PlantCandidate> candidates;
  final String? errorMessage;
  final VoidCallback onCancel;
  final ValueChanged<PlantCandidate> onSelectMatch;
  const _MatchesView({required this.candidates, this.errorMessage, required this.onSelectMatch, required this.onCancel});

  @override
  State<_MatchesView> createState() => _MatchesViewState();
}

class _MatchesViewState extends State<_MatchesView> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.82);

  String _getSpanishCommonName(List<String> commonNames, String scientificName) {
    if (commonNames.isEmpty) return scientificName;

    final englishWords = [
      'weed', 'plant', 'grass', 'fern', 'tree', 'common', 'stinking', 'daisy',
      'lily', 'moss', 'vine', 'bush', 'creeper', 'flower', 'leaf', 'dogfennel',
      'chamomile', 'poison', 'ivy', 'oak', 'pine', 'palm', 'rose', 'orchid',
      'creeping', 'climbing', 'sweet', 'wild', 'false', 'true', 'water', 'wood',
      'giant', 'dwarf', 'trailing', 'weeping', 'spotted', 'striped', 'cheese',
      'shield', 'sword', 'brake', 'maidenhair', 'bird', 'nest', 'spider', 'snake',
      'mother', 'law', 'tongue', 'money', 'jade', 'rubber', 'fig', 'ivy', 'pothos'
    ];

    for (var name in commonNames) {
      final lowerName = name.toLowerCase();
      if (lowerName == scientificName.toLowerCase()) continue;

      bool isEnglish = false;
      for (var word in englishWords) {
        if (RegExp(r'\b' + word + r'\b').hasMatch(lowerName)) {
          isEnglish = true;
          break;
        }
      }
      if (!isEnglish) {
        return name;
      }
    }

    return commonNames.first;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: GardenColors.forest));
    }
    final currentMatch = widget.candidates[_currentIndex];
    final currentMatchName = _getSpanishCommonName(currentMatch.commonNames, currentMatch.scientificName);

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
                  '${widget.candidates.length} POSIBLES COINCIDENCIAS',
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

        if (widget.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Cards list using PageView
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.candidates.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final match = widget.candidates[index];
              final isActive = index == _currentIndex;
              final pct = (match.probability * 100).round();
              final name = _getSpanishCommonName(match.commonNames, match.scientificName);
              final species = match.scientificName;
              const emoji = '🌿';
              final tags = ['Planta', 'Detectada'];
              
              // Color badge logic
              final Color badgeColor = pct >= 80
                  ? GardenColors.leafDark
                  : pct >= 60
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
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                              child: match.imageUrl != null
                                  ? SizedBox.expand(
                                      child: Image.network(
                                        match.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Text(
                                              emoji,
                                              style: const TextStyle(fontSize: 84),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Center(
                                      child: AnimatedScale(
                                        duration: const Duration(milliseconds: 300),
                                        scale: isActive ? 1.15 : 1.0,
                                        child: Text(
                                          emoji,
                                          style: const TextStyle(fontSize: 84),
                                        ),
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
                                    '${pct}%',
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
                              name,
                              style: GardenTextStyles.title.copyWith(
                                color: GardenColors.ink,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              species,
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
                              children: tags.map((tag) {
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
                  onPressed: () => widget.onSelectMatch(currentMatch),
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
                        'Es la $currentMatchName, confirmar',
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
