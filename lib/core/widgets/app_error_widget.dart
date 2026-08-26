import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../utils/error_handler.dart';

class AppErrorWidget extends StatefulWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? title;

  const AppErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.title,
  });

  @override
  State<AppErrorWidget> createState() => _AppErrorWidgetState();
}

class _AppErrorWidgetState extends State<AppErrorWidget> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _startAutoRetry();
  }

  void _startAutoRetry() {
    if (widget.onRetry == null) return;
    
    // Listen to network changes (Industry Standard Event Listener)
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (_isRetrying || !mounted) return;
      
      // If any of the results indicate we are online
      final isOnline = results.any((result) => 
          result == ConnectivityResult.mobile || 
          result == ConnectivityResult.wifi || 
          result == ConnectivityResult.ethernet || 
          result == ConnectivityResult.vpn);
          
      if (isOnline) {
        _isRetrying = true;
        _subscription?.cancel();
        if (mounted) {
          widget.onRetry!();
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: AppColors.reject.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded, // Use wifi_off to imply connection issue (most common for Postgrest/Socket)
                size: 48,
                color: AppColors.reject,
              ),
            ),
            const SizedBox(height: AppSizes.p16),
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.p8),
            ],
            Text(
              AppErrorHandler.getMessage(widget.error),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: AppSizes.p24),
              ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r24),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
