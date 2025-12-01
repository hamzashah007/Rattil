import 'package:flutter/material.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/utils/theme_colors.dart';
import 'package:rattil/widgets/package_info_card.dart';

class EnrollNowScreen extends StatelessWidget {
  final bool isDarkMode;
  final Package package;
  const EnrollNowScreen({Key? key, required this.isDarkMode, required this.package}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? ThemeColors.darkBg : ThemeColors.lightBg;
    final cardColor = isDarkMode ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
    final subtextColor = isDarkMode ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;
    final accentColor = ThemeColors.primaryTeal;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Text('Make Payment', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Package Info Card
            PackageInfoCard(package: package, isDarkMode: isDarkMode),
            const SizedBox(height: 24),
            Text('Make Payment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: subtextColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: subtextColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: subtextColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                child: const Text('Make Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
