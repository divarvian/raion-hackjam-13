import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class SnackbarUtils {
  SnackbarUtils._();

  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
  }) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.support,
      icon: Icons.check_circle_outline,
      action: action,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
  }) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.reject,
      icon: Icons.error_outline,
      action: action,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
  }) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.info,
      icon: Icons.info_outline,
      action: action,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
  }) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_amber_outlined,
      action: action,
      duration: duration,
    );
  }

  static void _showSnackbar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    SnackBarAction? action,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: duration ?? const Duration(seconds: 3),
        action: action,
      ),
    );
  }
}
