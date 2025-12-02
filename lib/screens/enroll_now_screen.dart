import 'package:flutter/material.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/utils/theme_colors.dart';
import 'package:rattil/widgets/package_info_card.dart';

class EnrollNowScreen extends StatelessWidget {
  final bool isDarkMode;
  final Package package;
  const EnrollNowScreen({
    Key? key,
    required this.isDarkMode,
    required this.package,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? ThemeColors.darkBg : Colors.white;
    final cardColor = isDarkMode ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
    final subtextColor = isDarkMode
        ? ThemeColors.darkSubtitle
        : ThemeColors.lightSubtitle;
    final accentColor = ThemeColors.primaryTeal;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Text(
          'Make Payment',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
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
            Text(
              'Make Payment',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: subtextColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: subtextColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: subtextColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            SizedBox(
  width: double.infinity,
  child: InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {},
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0d9488), Color(0xFF14b8a6)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Make Payment',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}
