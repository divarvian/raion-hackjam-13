import 'package:flutter/material.dart';

/// Color palette Kawal.Z — berdasarkan analisis mockup PRD
class AppColors {
  AppColors._();

  // === PRIMARY ===
  static const primary = Color(0xFF1A237E);
  static const primaryLight = Color(0xFF3949AB);
  static const primaryDark = Color(0xFF0D1442);

  // === ACCENT ===
  static const accent = Color(0xFFFFD600);
  static const accentOrange = Color(0xFFFF9800);

  // === SEMANTIC (Vote Actions) ===
  static const support = Color(0xFF4CAF50);
  static const reject = Color(0xFFE53935);
  static const warning = Color(0xFFFFA726);
  static const info = Color(0xFF42A5F5);

  // === BACKGROUND ===
  static const bgLight = Color(0xFFF8F9FA);
  static const bgDark = Color(0xFF0F1B2D);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF1A2744);

  // === TEXT ===
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textOnDark = Color(0xFFFFFFFF);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // === CATEGORY COLORS ===
  static const categoryPolitik = Color(0xFFE53935);
  static const categoryEkonomi = Color(0xFF1E88E5);
  static const categorySosial = Color(0xFFFFA726);
  static const categoryHukum = Color(0xFF7E57C2);

  // === LEVEL COLORS ===
  static const level1 = Color(0xFFFFD700); // Calon Menteri - Gold
  static const level2 = Color(0xFF9C27B0); // Suhu Pergerakan - Purple
  static const level3 = Color(0xFF2196F3); // Pengamat Warkop - Blue
  static const level4 = Color(0xFF4CAF50); // Warga Aktif - Green
  static const level5 = Color(0xFFE53935); // Warga Rebahan - Red

  // === DIVIDER / BORDER ===
  static const divider = Color(0xFFE5E7EB);
  static const border = Color(0xFFD1D5DB);

  /// Mendapatkan warna kategori berdasarkan nama kategori
  static Color getCategoryColor(String category) {
    return switch (category.toLowerCase()) {
      'politik' => categoryPolitik,
      'ekonomi' => categoryEkonomi,
      'sosial' => categorySosial,
      'hukum' => categoryHukum,
      _ => primaryLight,
    };
  }

  /// Mendapatkan warna level berdasarkan nomor level
  static Color getLevelColor(int level) {
    return switch (level) {
      1 => level1,
      2 => level2,
      3 => level3,
      4 => level4,
      5 => level5,
      _ => Colors.grey,
    };
  }
}
