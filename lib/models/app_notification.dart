import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final IconData icon;
  final Color iconColor;
  final bool isRead;
  final String? payload;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
    this.payload,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    IconData? icon,
    Color? iconColor,
    bool? isRead,
    String? payload,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
    );
  }
}
