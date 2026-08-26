import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Utilitas kalkulasi XP & Level Gamifikasi
///
/// Level System:
/// - Level 5: Warga Rebahan    (0 – 100 XP)     — terendah
/// - Level 4: Warga Aktif      (101 – 300 XP)
/// - Level 3: Pengamat Warkop  (301 – 500 XP)
/// - Level 2: Suhu Pergerakan  (501 – 1000 XP)
/// - Level 1: Calon Menteri    (> 1000 XP)       — tertinggi
class XpCalculator {
  XpCalculator._();

  /// Hitung level berdasarkan total XP
  static int calculateLevel(int totalXp) {
    if (totalXp > 1000) return 1;
    if (totalXp > 500) return 2;
    if (totalXp > 300) return 3;
    if (totalXp > 100) return 4;
    return 5;
  }

  /// Nama gelar berdasarkan level
  static String getLevelTitle(int level) {
    return switch (level) {
      1 => 'Calon Menteri',
      2 => 'Suhu Pergerakan',
      3 => 'Pengamat Warkop',
      4 => 'Warga Aktif',
      5 => 'Warga Rebahan',
      _ => 'Unknown',
    };
  }

  /// Deskripsi motivasional level
  static String getLevelDescription(int level) {
    return switch (level) {
      1 => 'Kamu adalah penggerak perubahan! Terus suarakan pendapatmu.',
      2 => 'Suaramu berpengaruh dan menginspirasi banyak orang.',
      3 => 'Kritis, peduli, dan selalu update isu. Good job!',
      4 => 'Mulai ambil bagian, satu langkah lebih baik!',
      5 => 'Semua orang mulai dari sini. Yuk, mulai peduli!',
      _ => '',
    };
  }

  /// XP minimum untuk mencapai level tertentu
  static int xpMinForLevel(int level) {
    return switch (level) {
      1 => 1001,
      2 => 501,
      3 => 301,
      4 => 101,
      5 => 0,
      _ => 0,
    };
  }

  /// XP yang dibutuhkan untuk naik ke level berikutnya
  static int xpForNextLevel(int currentLevel) {
    return switch (currentLevel) {
      5 => 101,
      4 => 301,
      3 => 501,
      2 => 1001,
      1 => 1001, // Sudah max level
      _ => 0,
    };
  }

  /// Progress percentage menuju level berikutnya (0.0 - 1.0)
  static double progressToNextLevel(int totalXp, int currentLevel) {
    if (currentLevel == 1) return 1.0; // Max level

    final currentMin = xpMinForLevel(currentLevel);
    final nextMin = xpForNextLevel(currentLevel);
    final range = nextMin - currentMin;
    if (range <= 0) return 1.0;

    final progress = totalXp - currentMin;
    return (progress / range).clamp(0.0, 1.0);
  }

  /// Sisa XP yang dibutuhkan untuk level berikutnya
  static int xpRemainingForNextLevel(int totalXp, int currentLevel) {
    if (currentLevel == 1) return 0;
    final nextMin = xpForNextLevel(currentLevel);
    return (nextMin - totalXp).clamp(0, nextMin);
  }

  /// Warna badge berdasarkan level
  static Color getLevelColor(int level) => AppColors.getLevelColor(level);

  /// Icon untuk source type XP transaction
  static IconData getSourceIcon(String sourceType) {
    return switch (sourceType) {
      'vote' => Icons.how_to_vote_rounded,
      'article_read' => Icons.chrome_reader_mode_rounded,
      'flashcard_complete' => Icons.school_rounded,
      _ => Icons.bolt_rounded,
    };
  }

  /// Label untuk source type
  static String getSourceLabel(String sourceType) {
    return switch (sourceType) {
      'vote' => 'Swipe Voting',
      'article_read' => 'Baca Artikel',
      'flashcard_complete' => 'Flashcard Selesai',
      _ => 'Aktivitas',
    };
  }
}
