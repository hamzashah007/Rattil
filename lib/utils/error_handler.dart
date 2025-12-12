import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

/// Custom exception class for app-specific errors
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Error types for categorizing errors
enum ErrorType {
  network,
  authentication,
  validation,
  server,
  permission,
  notFound,
  unknown,
}

/// Error result class to provide structured error information
class ErrorResult {
  final String title;
  final String message;
  final ErrorType type;
  final String? actionText;

  ErrorResult({
    required this.title,
    required this.message,
    required this.type,
    this.actionText,
  });
}

/// Centralized error handler for the app
class ErrorHandler {
  /// Get user-friendly error message from Firebase Auth errors
  static ErrorResult handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    }
    
    if (error is FirebaseException) {
      return _handleFirebaseError(error);
    }
    
    if (error is SocketException || error.toString().contains('SocketException')) {
      return ErrorResult(
        title: 'No Internet Connection',
        message: 'Please check your internet connection and try again.',
        type: ErrorType.network,
        actionText: 'Retry',
      );
    }
    
    return ErrorResult(
      title: 'Something Went Wrong',
      message: 'An unexpected error occurred. Please try again later.',
      type: ErrorType.unknown,
    );
  }

  /// Handle Firebase Auth specific errors with user-friendly messages
  static ErrorResult _handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      // Sign In Errors
      case 'user-not-found':
        return ErrorResult(
          title: 'Account Not Found',
          message: 'No account exists with this email address. Please check your email or create a new account.',
          type: ErrorType.authentication,
          actionText: 'Sign Up',
        );
      
      case 'wrong-password':
        return ErrorResult(
          title: 'Incorrect Password',
          message: 'The password you entered is incorrect. Please try again or reset your password.',
          type: ErrorType.authentication,
          actionText: 'Forgot Password?',
        );
      
      case 'invalid-credential':
        return ErrorResult(
          title: 'Invalid Credentials',
          message: 'The email or password you entered is incorrect. Please check your credentials and try again.',
          type: ErrorType.authentication,
        );
      
      case 'invalid-email':
        return ErrorResult(
          title: 'Invalid Email',
          message: 'Please enter a valid email address.',
          type: ErrorType.validation,
        );
      
      case 'user-disabled':
        return ErrorResult(
          title: 'Account Disabled',
          message: 'This account has been disabled. Please contact support for assistance.',
          type: ErrorType.authentication,
          actionText: 'Contact Support',
        );
      
      // Sign Up Errors
      case 'email-already-in-use':
        return ErrorResult(
          title: 'Email Already Registered',
          message: 'An account with this email already exists. Please sign in or use a different email.',
          type: ErrorType.authentication,
          actionText: 'Sign In',
        );
      
      case 'weak-password':
        return ErrorResult(
          title: 'Weak Password',
          message: 'Please choose a stronger password. Use at least 8 characters with letters and numbers.',
          type: ErrorType.validation,
        );
      
      case 'operation-not-allowed':
        return ErrorResult(
          title: 'Operation Not Allowed',
          message: 'This sign-in method is not enabled. Please contact support.',
          type: ErrorType.permission,
        );
      
      // Password Reset Errors
      case 'expired-action-code':
        return ErrorResult(
          title: 'Link Expired',
          message: 'This password reset link has expired. Please request a new one.',
          type: ErrorType.authentication,
        );
      
      case 'invalid-action-code':
        return ErrorResult(
          title: 'Invalid Link',
          message: 'This password reset link is invalid. Please request a new one.',
          type: ErrorType.authentication,
        );
      
      // Rate Limiting
      case 'too-many-requests':
        return ErrorResult(
          title: 'Too Many Attempts',
          message: 'You\'ve made too many attempts. Please wait a few minutes before trying again.',
          type: ErrorType.authentication,
        );
      
      // Network Errors
      case 'network-request-failed':
        return ErrorResult(
          title: 'Connection Error',
          message: 'Unable to connect to the server. Please check your internet connection.',
          type: ErrorType.network,
          actionText: 'Retry',
        );
      
      // Account Errors
      case 'requires-recent-login':
        return ErrorResult(
          title: 'Re-authentication Required',
          message: 'For security, please sign out and sign in again to complete this action.',
          type: ErrorType.authentication,
        );

      case 'account-exists-with-different-credential':
        return ErrorResult(
          title: 'Account Exists',
          message: 'An account already exists with a different sign-in method. Try signing in with a different method.',
          type: ErrorType.authentication,
        );

      default:
        return ErrorResult(
          title: 'Authentication Error',
          message: error.message ?? 'An authentication error occurred. Please try again.',
          type: ErrorType.authentication,
        );
    }
  }

  /// Handle general Firebase errors
  static ErrorResult _handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return ErrorResult(
          title: 'Access Denied',
          message: "You don't have permission to perform this action.\nDetails: ${error.message ?? error.toString()}",
          type: ErrorType.permission,
        );
      case 'unavailable':
        return ErrorResult(
          title: 'Service Unavailable',
          message: 'The service is temporarily unavailable. Please try again later.',
          type: ErrorType.server,
          actionText: 'Retry',
        );
      case 'not-found':
        return ErrorResult(
          title: 'Not Found',
          message: 'The requested resource was not found.',
          type: ErrorType.notFound,
        );
      case 'cancelled':
        return ErrorResult(
          title: 'Operation Cancelled',
          message: 'The operation was cancelled.',
          type: ErrorType.unknown,
        );
      default:
        return ErrorResult(
          title: 'Error',
          message: (error.message != null && error.message!.isNotEmpty)
              ? 'An error occurred: ${error.message}'
              : 'An error occurred. Details: ${error.toString()}',
          type: ErrorType.unknown,
        );
    }
  }

  /// Get a simple string message for snackbar display
  static String getSimpleMessage(dynamic error) {
    final result = handleAuthError(error);
    return result.message;
  }

  /// Check if error is network related
  static bool isNetworkError(dynamic error) {
    if (error is SocketException) return true;
    if (error is FirebaseException && error.code == 'unavailable') return true;
    if (error.toString().contains('SocketException')) return true;
    if (error.toString().contains('network')) return true;
    return false;
  }

  /// Check if user should retry the action
  static bool shouldRetry(ErrorType type) {
    return type == ErrorType.network || type == ErrorType.server;
  }
}
