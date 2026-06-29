import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema tipográfico global de Gossip Garden.
/// Basado en la escala del mockup de referencia.
class GardenTextStyles {
  GardenTextStyles._();

  /// Títulos grandes de pantalla (30–32px)
  static final TextStyle display = GoogleFonts.quicksand(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.15,
  );

  /// Subtítulos de sección (17px)
  static final TextStyle title = GoogleFonts.quicksand(
    fontSize: 17,
    fontWeight: FontWeight.w700, // Quicksand looks better w700
    letterSpacing: -0.1,
    height: 1.3,
  );

  /// Cuerpo principal (15px)
  static final TextStyle body = GoogleFonts.nunito(
    fontSize: 15,
    fontWeight: FontWeight.w600, // Nunito looks good on w600 for body
    height: 1.5,
  );

  /// Cuerpo secundario / subtítulos de card (13px)
  static final TextStyle bodySmall = GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  /// Etiquetas / uppercase / chips (11px)
  static final TextStyle label = GoogleFonts.nunito(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.3,
  );
}
