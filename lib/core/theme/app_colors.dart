import 'package:flutter/material.dart';

/// GrowIn — Palet "Mono Glass" (hitam & putih).
/// Nama-nama field sengaja dipertahankan sama persis dengan versi
/// sebelumnya supaya seluruh layar yang sudah ada otomatis ikut
/// berubah tema tanpa perlu diedit satu-satu.
class AppColors {
  AppColors._();

  // Base
  static const Color black = Color(0xFF111111);
  static const Color charcoal = Color(0xFF262626);
  static const Color darkGrey = Color(0xFF4A4A4A);
  static const Color midGrey = Color(0xFF8A8A8A);
  static const Color lightGrey = Color(0xFFE2E2E2);
  static const Color offWhite = Color(0xFFF7F7F7);
  static const Color white = Color(0xFFFFFFFF);

  // Primary — hitam pekat, dipakai untuk CTA & aksen aktif
  static const Color primary = Color(0xFF141414);
  static const Color primaryContainer = Color(0xFF000000);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Aksen tambahan (dulu warna-warni, sekarang abu netral)
  static const Color accentRose = Color(0xFFB0B0B0);
  static const Color accentPeach = Color(0xFFD6D6D6);
  static const Color accentSage = Color(0xFF9A9A9A);
  static const Color accentClay = Color(0xFF3A3A3A);

  // Background & surface
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFFFFFFFF);

  // Glass panes
  static const Color glassLight = Color(0x99FFFFFF); // putih 60%
  static const Color glassBorderLight = Color(0xB3FFFFFF); // putih 70%
  static const Color glassDark = Color(0x66000000); // hitam 40%
  static const Color glassBorderDark = Color(0x40FFFFFF); // putih 25%

  // Text
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6E6E6E);
  static const Color textOnDark = Color(0xFFF5F5F5);
  static const Color textOnDarkSecondary = Color(0xFFC7C7C7);

  // Status (dibuat tetap grayscale agar konsisten dengan tema mono)
  static const Color success = Color(0xFF2E2E2E);
  static const Color warning = Color(0xFF5A5A5A);
  static const Color error = Color(0xFF1A1A1A);
  static const Color outlineVariant = Color(0xFFDCDCDC);

  // Gradient mesh background — putih ke abu lembut, TANPA bubble/blob
  static const List<Color> meshGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFF2F2F2),
    Color(0xFFEAEAEA),
    Color(0xFFF7F7F7),
  ];

  static const List<Color> meshGradientDark = [
    Color(0xFF000000),
    Color(0xFF1A1A1A),
    Color(0xFF0D0D0D),
    Color(0xFF000000),
  ];

  /// Gradient hero hitam-putih.
  static const List<Color> heroGradient = [
    Color(0xFFEDEDED),
    Color(0xFFBFBFBF),
    Color(0xFF5C5C5C),
    Color(0xFF111111),
  ];
}
