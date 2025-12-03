import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/utils/theme_colors.dart';
import 'package:rattil/widgets/package_info_card.dart';
import 'package:rattil/screens/payment_screen.dart';

class EnrollNowScreen extends StatefulWidget {
  final Package package;
  const EnrollNowScreen({
    Key? key,
    required this.package,
  }) : super(key: key);

  @override
  State<EnrollNowScreen> createState() => _EnrollNowScreenState();
}

class _EnrollNowScreenState extends State<EnrollNowScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final package = widget.package;
    final bgColor = isDarkMode ? ThemeColors.darkBg : Colors.white;
    final cardColor = isDarkMode ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;

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
            PackageInfoCard(package: package),
            const SizedBox(height: 24),
           
         
            SizedBox(
              width: double.infinity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.ease,
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            selectedPackage: package,
                          ),
                        ),
                      );
                    },
                    child: Container(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
