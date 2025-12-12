// This screen is a placeholder for future Apple In-App Purchase integration.
// Payment functionality has been temporarily disabled.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/utils/theme_colors.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final bgColor = isDarkMode ? ThemeColors.darkBg : Colors.white;
    final cardColor = isDarkMode ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
    final subtitleColor = isDarkMode ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Payment Success',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 64,
                color: subtitleColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Payments are not yet enabled.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Subscriptions will be available soon via Apple In-App Purchase.',
                style: TextStyle(
                  fontSize: 14,
                  color: subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
