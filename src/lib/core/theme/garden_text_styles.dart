import 'package:flutter/material.dart';

/// Sistema tipográfico global de Gossip Garden.
/// Basado en la escala del mockup de referencia.
class GardenTextStyles {
  GardenTextStyles._();

  /// Títulos grandes de pantalla (30–32px)
  static const TextStyle display = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.15,
  );

  /// Subtítulos de sección (17px)
  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.3,
  );

  /// Cuerpo principal (15px)
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Cuerpo secundario / subtítulos de card (13px)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  /// Etiquetas / uppercase / chips (11px)
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.3,
  );
}
