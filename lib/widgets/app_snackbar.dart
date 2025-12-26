import 'package:flutter/material.dart';
import 'package:rattil/utils/theme_colors.dart';
import 'package:rattil/utils/error_handler.dart';

/// Custom snackbar helper for consistent error/success messages
class AppSnackbar {
  /// Show an error snackbar with improved styling
  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    String? actionText,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackbar(
      context,
      message: message,
      title: title,
      icon: Icons.error_outline,
      backgroundColor: const Color(0xFFEF4444),
      actionText: actionText,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Show a success snackbar
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackbar(
      context,
      message: message,
      title: title,
      icon: Icons.check_circle_outline,
      backgroundColor: ThemeColors.primaryTeal,
      duration: duration,
    );
  }

  /// Show a warning snackbar
  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    String? actionText,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackbar(
      context,
      message: message,
      title: title,
      icon: Icons.warning_amber_outlined,
      backgroundColor: const Color(0xFFF59E0B),
      actionText: actionText,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Show an info snackbar
  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackbar(
      context,
      message: message,
      title: title,
      icon: Icons.info_outline,
      backgroundColor: const Color(0xFF3B82F6),
      duration: duration,
    );
  }

  /// Show error from ErrorResult
  static void showErrorResult(
    BuildContext context, {
    required ErrorResult errorResult,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackbar(
      context,
      message: errorResult.message,
      title: errorResult.title,
      icon: _getIconForErrorType(errorResult.type),
      backgroundColor: _getColorForErrorType(errorResult.type),
      actionText: errorResult.actionText,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Show network error with retry option
  static void showNetworkError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showError(
      context,
      title: 'No Internet Connection',
      message: 'Please check your connection and try again.',
      actionText: 'Retry',
      onAction: onRetry,
      duration: const Duration(seconds: 5),
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

  static void _showSnackbar(
    BuildContext context, {
    required String message,
    String? title,
    required IconData icon,
    required Color backgroundColor,
    String? actionText,
    VoidCallback? onAction,
    required Duration duration,
  }) {
    // Clear any existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();

    final snackBar = SnackBar(
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 60),
      duration: duration,
      action: actionText != null
          ? SnackBarAction(
              label: actionText,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// Extension on BuildContext for easy access to snackbar methods
extension SnackbarExtension on BuildContext {
  void showErrorSnackbar(String message, {String? title}) {
    AppSnackbar.showError(this, message: message, title: title);
  }

  void showSuccessSnackbar(String message, {String? title}) {
    AppSnackbar.showSuccess(this, message: message, title: title);
  }

  void showWarningSnackbar(String message, {String? title}) {
    AppSnackbar.showWarning(this, message: message, title: title);
  }

  void showInfoSnackbar(String message, {String? title}) {
    AppSnackbar.showInfo(this, message: message, title: title);
  }
}
