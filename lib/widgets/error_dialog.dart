import 'package:flutter/material.dart';
import 'package:rattil/utils/theme_colors.dart';
import 'package:rattil/utils/error_handler.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/theme_provider.dart';

/// Error dialog for displaying detailed error information
class ErrorDialog {
  /// Show a detailed error dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryAction,
    VoidCallback? onSecondaryAction,
    IconData? icon,
    Color? iconColor,
  }) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = isDark ? ThemeColors.darkText : ThemeColors.lightText;
    final subtitleColor = isDark ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFFEF4444)).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                color: iconColor ?? const Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (primaryButtonText != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onPrimaryAction?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    primaryButtonText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (secondaryButtonText != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onSecondaryAction?.call();
                  },
                  child: Text(
                    secondaryButtonText,
                    style: TextStyle(color: subtitleColor),
                  ),
                ),
              ),
            ],
            if (primaryButtonText == null && secondaryButtonText == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show error from ErrorResult
  static Future<void> showFromResult(
    BuildContext context, {
    required ErrorResult errorResult,
    VoidCallback? onPrimaryAction,
    VoidCallback? onSecondaryAction,
  }) async {
    await show(
      context,
      title: errorResult.title,
      message: errorResult.message,
      primaryButtonText: errorResult.actionText ?? 'Try Again',
      secondaryButtonText: errorResult.actionText != null ? 'Cancel' : null,
      onPrimaryAction: onPrimaryAction,
      onSecondaryAction: onSecondaryAction,
      icon: _getIconForErrorType(errorResult.type),
      iconColor: _getColorForErrorType(errorResult.type),
    );
  }

  /// Show network error dialog
  static Future<void> showNetworkError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    await show(
      context,
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      primaryButtonText: 'Retry',
      secondaryButtonText: 'Cancel',
      onPrimaryAction: onRetry,
      icon: Icons.wifi_off,
      iconColor: const Color(0xFFF59E0B),
    );
  }

  /// Show session expired dialog
  static Future<void> showSessionExpired(
    BuildContext context, {
    required VoidCallback onSignIn,
  }) async {
    await show(
      context,
      title: 'Session Expired',
      message: 'Your session has expired. Please sign in again to continue.',
      primaryButtonText: 'Sign In',
      onPrimaryAction: onSignIn,
      icon: Icons.lock_outline,
      iconColor: const Color(0xFFF59E0B),
    );
  }

  static IconData _getIconForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock_outline;
      case ErrorType.validation:
        return Icons.edit_note;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.permission:
        return Icons.block;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  static Color _getColorForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return const Color(0xFFF59E0B); // Orange
      case ErrorType.authentication:
        return const Color(0xFFEF4444); // Red
      case ErrorType.validation:
        return const Color(0xFFF59E0B); // Orange
      case ErrorType.server:
        return const Color(0xFFEF4444); // Red
      case ErrorType.permission:
        return const Color(0xFFEF4444); // Red
      case ErrorType.notFound:
        return const Color(0xFF6B7280); // Gray
      case ErrorType.unknown:
        return const Color(0xFFEF4444); // Red
    }
  }
}
