import 'package:flutter/material.dart';

enum _IdentifyState { idle, scanning, result }

class PlantIdentifyScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCompleted;

  const PlantIdentifyScreen({super.key, this.onBack, this.onCompleted});

  @override
  State<PlantIdentifyScreen> createState() => _PlantIdentifyScreenState();
}

class _PlantIdentifyScreenState extends State<PlantIdentifyScreen>
    with SingleTickerProviderStateMixin {
  _IdentifyState _state = _IdentifyState.idle;
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
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
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _startIdentification() async {
    setState(() => _state = _IdentifyState.scanning);
    _scanController.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 2400));
    if (mounted) {
      _scanController.stop();
      setState(() => _state = _IdentifyState.result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A6741)),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: const Text(
          'Identificar planta',
          style: TextStyle(color: Color(0xFF4A6741), fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _IdentifyState.idle:
        return _buildIdle();
      case _IdentifyState.scanning:
        return _buildScanning();
      case _IdentifyState.result:
        return _buildResult();
    }
  }

  Widget _buildIdle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Viewfinder
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF1A2E1A),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF4A6741), width: 3),
          ),
          child: Stack(
            children: [
              // Fondo oscuro simulando cámara
              ClipRRect(
                borderRadius: BorderRadius.circular(29),
                child: Container(
                  color: const Color(0xFF1A2E1A),
                  child: Center(
                    child: Icon(
                      Icons.local_florist,
                      size: 80,
                      color: const Color(0xFF4A6741).withOpacity(0.4),
                    ),
                  ),
                ),
              ),
              // Esquinas del visor
              ..._buildViewfinderCorners(),
              // Texto de instrucción
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Apunta a tu planta',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Enfoca tu planta',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF2D2D2D)),
        ),
        const SizedBox(height: 8),
        Text(
          'Tocaremos el botón para identificarla con IA',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startIdentification,
            icon: const Icon(Icons.document_scanner_rounded),
            label: const Text(
              'Identificar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A6741),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanning() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Viewfinder con línea de escaneo animada
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF1A2E1A),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF4A6741), width: 3),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(29),
                child: Center(
                  child: Icon(
                    Icons.local_florist,
                    size: 80,
                    color: const Color(0xFF4A6741).withOpacity(0.4),
                  ),
                ),
              ),
              // Línea de escaneo animada
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (_, __) => Positioned(
                  top: _scanAnimation.value * 260,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF8BC34A).withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ..._buildViewfinderCorners(),
            ],
          ),
        ),
        const SizedBox(height: 40),
        const CircularProgressIndicator(
          color: Color(0xFF4A6741),
          strokeWidth: 3,
        ),
        const SizedBox(height: 20),
        const Text(
          'Analizando...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Consultando base de datos botánica',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Imagen con check overlay
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4A6741).withOpacity(0.1),
                border: Border.all(color: const Color(0xFF4A6741), width: 3),
              ),
              child: const Icon(Icons.local_florist, size: 64, color: Color(0xFF4A6741)),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          '¡Identificada!',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Monducuru',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF2D2D2D)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Opuntia monacantha',
          style: TextStyle(
            fontSize: 18,
            fontStyle: FontStyle.italic,
            color: Color(0xFF4A6741),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Barra de confianza
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4A6741).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, color: Color(0xFF4A6741), size: 20),
              const SizedBox(width: 8),
              const Text(
                '97% de confianza',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A6741),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Cactus nativo de Sudamérica. Espinas prominentes. Resistente a la sequía. Con personalidad.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onCompleted ?? () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A6741),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            child: const Text(
              '¡Esta es mi planta!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildViewfinderCorners() {
    const color = Color(0xFF8BC34A);
    const size = 24.0;
    const thickness = 3.0;
    return [
      // Top-left
      Positioned(
        top: 12, left: 12,
        child: _corner(color, size, thickness, top: true, left: true),
      ),
      // Top-right
      Positioned(
        top: 12, right: 12,
        child: _corner(color, size, thickness, top: true, left: false),
      ),
      // Bottom-left
      Positioned(
        bottom: 12, left: 12,
        child: _corner(color, size, thickness, top: false, left: true),
      ),
      // Bottom-right
      Positioned(
        bottom: 12, right: 12,
        child: _corner(color, size, thickness, top: false, left: false),
      ),
    ];
  }

  Widget _corner(Color color, double size, double thickness,
      {required bool top, required bool left}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(color, thickness, top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool top;
  final bool left;

  _CornerPainter(this.color, this.thickness, {required this.top, required this.left});

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
