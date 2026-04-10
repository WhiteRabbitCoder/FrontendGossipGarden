import 'package:flutter/material.dart';

class AppDesignSystem {
  // 1. Los Colores de tu Tailwind
  static const Color primary = Color(0xFF8BA888); // Sage Green
  static const Color secondary = Color(0xFFF3F4F6);
  static const Color accent = Color(0xFFFDE68A); // CTA Yellow
  static const Color destructive = Color(0xFFEF4444);
  static const Color background = Colors.white;
  static const Color card = Color(0xFFFFFFFF);
  
  // 2. Las Sombras (Shadows) de tus archivos .tsx
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowSoft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  // 3. Estilos de Botón (Basado en button.tsx)
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
  );
  
  static ButtonStyle ctaButton = ElevatedButton.styleFrom(
    backgroundColor: accent,
    foregroundColor: Colors.black,
    elevation: 2,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
  );
  static void showAppDrawer(BuildContext context, Widget child) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Esa "rayita" gris que pusiste en drawer.tsx
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child,
          ],
        ),
      ),
    );
}