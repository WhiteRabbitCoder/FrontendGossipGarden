import 'package:flutter/material.dart';
import '../../../../core/utils/garden_snackbar.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // HARDCODE(demo): valoración simulada; no se envía a analytics ni Play Store in-app review.
  // TODO(backend): POST /feedback o integrar In-App Review de la tienda.
  Future<void> _submitRating() async {
    if (_rating == 0) {
      GardenSnackbar.show(context, message: '');.showSnackBar(
        const SnackBar(content: Text('Selecciona una puntuación antes de enviar.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    GardenSnackbar.show(context, message: '');.showSnackBar(
      const SnackBar(content: Text('¡Gracias por tu opinión!')),
    );
    Navigator.pop(context);
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
            Text(
              'Calificar la app',
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Tu opinión nos ayuda a mejorar',
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GardenColors.creamPaper),
                ),
                child: Column(
                  children: [
                    const GardenIcon(asset: GardenIcons.plantEco, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      '¿Cómo valoras Gossip Garden?',
                      style: GardenTextStyles.title.copyWith(
                        color: GardenColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tu feedback nos ayuda a cuidar mejor tu jardín digital.',
                      style: GardenTextStyles.bodySmall.copyWith(color: GardenColors.inkSoft),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        final isSelected = starIndex <= _rating;
                        return IconButton(
                          onPressed: () => setState(() => _rating = starIndex),
                          icon: GardenIcon(
                            asset: isSelected
                                ? GardenIcons.starFilled
                                : GardenIcons.starOutline,
                            size: 40,
                            opacity: isSelected ? 1.0 : 0.5,
                          ),
                        );
                      }),
                    ),
                    if (_rating > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        _ratingLabel(_rating),
                        style: GardenTextStyles.bodySmall.copyWith(
                          color: GardenColors.leafDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                      'COMENTARIO (OPCIONAL)',
                      style: GardenTextStyles.label.copyWith(
                        color: GardenColors.inkSoft,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Cuéntanos qué te gusta o qué mejorarías...',
                        hintStyle: GardenTextStyles.body.copyWith(color: GardenColors.inkSoft),
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
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: GardenTextStyles.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GardenColors.leafDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Enviar valoración',
                        style: GardenTextStyles.title.copyWith(color: Colors.white, fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Necesitamos mejorar';
      case 2:
        return 'Puede mejorar';
      case 3:
        return 'Está bien';
      case 4:
        return '¡Muy buena!';
      case 5:
        return '¡Excelente!';
      default:
        return '';
    }
  }
}
