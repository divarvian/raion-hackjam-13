import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Light theme untuk Kawal.Z
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.bgLight,
        error: AppColors.reject,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

       // Elevated Button
       elevatedButtonTheme: ElevatedButtonThemeData(
         style: ElevatedButton.styleFrom(
           backgroundColor: AppColors.primary,
           foregroundColor: AppColors.textOnPrimary,
           elevation: 0,
           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
           ),
           textStyle: GoogleFonts.poppins(
             fontSize: 14,
             fontWeight: FontWeight.w600,
           ),
         ),
       ),

       // Outlined Button
       outlinedButtonTheme: OutlinedButtonThemeData(
         style: OutlinedButton.styleFrom(
           foregroundColor: AppColors.primary,
           side: const BorderSide(color: AppColors.primary),
           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
           ),
           textStyle: GoogleFonts.poppins(
             fontSize: 14,
             fontWeight: FontWeight.w600,
           ),
         ),
       ),

       // Text Button
       textButtonTheme: TextButtonThemeData(
         style: TextButton.styleFrom(
           foregroundColor: AppColors.primary,
           textStyle: GoogleFonts.poppins(
             fontSize: 14,
             fontWeight: FontWeight.w600,
           ),
         ),
       ),

       // Input Decoration
       inputDecorationTheme: InputDecorationTheme(
         filled: true,
         fillColor: Colors.white,
         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
         border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: const BorderSide(color: AppColors.border),
         ),
         enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: const BorderSide(color: AppColors.border),
         ),
         focusedBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: const BorderSide(color: AppColors.primary, width: 2),
         ),
         errorBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: const BorderSide(color: AppColors.reject),
         ),
         hintStyle: GoogleFonts.poppins(
           color: AppColors.textTertiary,
           fontSize: 14,
         ),
       ),

       // Divider
       dividerTheme: const DividerThemeData(
         color: AppColors.divider,
         thickness: 1,
         space: 1,
       ),

       // Chip
       chipTheme: ChipThemeData(
         backgroundColor: AppColors.bgLight,
         selectedColor: AppColors.primary,
         labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(20),
         ),
         side: const BorderSide(color: AppColors.border),
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
       ),

       // Text Theme
       textTheme: GoogleFonts.poppinsTextTheme(),
    );
  }
}
