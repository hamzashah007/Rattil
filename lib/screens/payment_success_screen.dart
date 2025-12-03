import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/utils/theme_colors.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String transactionId;
  final Package package;
  const PaymentSuccessScreen({Key? key, required this.transactionId, required this.package}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? ThemeColors.darkBg : ThemeColors.lightBg;
    final cardColor = isDark ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = isDark ? ThemeColors.darkText : ThemeColors.lightText;
    final subtitleColor = isDark ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;
    final tealPrimary = ThemeColors.primaryTeal;
    final tealDark = ThemeColors.primaryTealDark;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Payment Successful', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [tealPrimary, tealDark]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: tealPrimary.withOpacity(0.3), blurRadius: 24, offset: Offset(0, 8))],
                ),
                child: Center(
                  child: Icon(Icons.check_circle, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 24),
              Text('Payment Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 12),
              Text('Your payment for the ${package.name} has been processed.', style: TextStyle(fontSize: 16, color: subtitleColor), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Transaction ID: $transactionId', style: TextStyle(fontSize: 14, color: subtitleColor)),
              const SizedBox(height: 8),
              Text('Our team will contact you soon.', style: TextStyle(fontSize: 14, color: subtitleColor)),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 0)),
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  elevation: MaterialStateProperty.all(0),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                ),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF14b8a6), Color(0xFF0d9488)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Go to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
