import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const primary = Color(0xFF00D09C); // Emerald Green / Teal
  static const primaryDark = Color(0xFF00A87E);
  static const secondary = Color(0xFF4C6EF5); // Indigo
  static const background = Color(0xFFF7F9FC); // Light Blue-Grey
  static const surface = Colors.white;
  static const textMain = Color(0xFF2D3436);
  static const textSecondary = Color(0xFF636E72);
  static const divider = Color(0xFFDFE6E9);
  static const danger = Color(0xFFFF4757);
  static const warning = Color(0xFFFFA502);
  static const success = Color(0xFF2ED573);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF00D09C), Color(0xFF00B882)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Mesh Gradient for Cards
  static const meshGradient = LinearGradient(
    colors: [Color(0xFF00D09C), Color(0xFF0984E3), Color(0xFF6C5CE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    )
  ];
  
  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 6),
    )
  ];

  // Text Styles
  static TextStyle get header1 => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textMain,
    letterSpacing: -0.5,
  );
  
  static TextStyle get title => GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textMain,
  );
  
  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 14,
    color: textSecondary,
    height: 1.5,
  );
}

class RoleTheme {
  // Warga: Biru + Biru Langit + Putih
  static const wargaPrimary = Color(0xFF2980B9);
  static const wargaSecondary = Color(0xFF87CEEB); // SkyBlue
  static const wargaBackground = Colors.white;
  static const wargaGradient = LinearGradient(
     colors: [Color(0xFF2980B9), Color(0xFF87CEEB)],
     begin: Alignment.topLeft,
     end: Alignment.bottomRight,
  );

  // Bendahara (Admin): Hijau Tua + Background Putih Modern
  static const adminPrimary = Color(0xFF1B5E20); // Dark Green
  static const adminSecondary = Color(0xFF2E7D32); 
  static const adminBackground = Color(0xFFF5F7FA); // Light Grey
  static const adminSurface = Colors.white; // White Cards
  static const adminText = Color(0xFF2D3436); // Dark Text
  static const adminGradient = LinearGradient(
     colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
     begin: Alignment.topLeft,
     end: Alignment.bottomRight,
  );

  // Ketua RT: Hijau Muda + Hijau Tua + Biru Langit + Putih
  static const rtPrimary = Color(0xFF66BB6A); // Light Green
  static const rtSecondary = Color(0xFF1B5E20); // Dark Green
  static const rtAccent = Color(0xFF87CEEB); // Sky Blue
  static const rtBackground = Colors.white;
  static const rtGradient = LinearGradient(
     colors: [Color(0xFF66BB6A), Color(0xFF1B5E20), Color(0xFF87CEEB)],
     begin: Alignment.topLeft,
     end: Alignment.bottomRight,
  );
}
