import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/providers/theme_provider.dart';

class TrialRequestSuccessScreen extends StatelessWidget {
  final Package package;
  const TrialRequestSuccessScreen({Key? key, required this.package}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? Color(0xFF111827) : Color(0xFFF9FAFB);
    final cardBg = isDark ? Color(0xFF1F2937) : Colors.white;
    final textColor = isDark ? Colors.white : Color(0xFF111827);
    final subtitleColor = isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280);
    final tealPrimary = Color(0xFF14b8a6);
    final tealDark = Color(0xFF0d9488);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 2,
        title: Text('Trial Requested', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
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
                  child: Icon(Icons.check_circle_outline, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 24),
              Text('Trial Request Submitted!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 12),
              Text('Your request for a trial of the ${package.name} package has been received.', style: TextStyle(fontSize: 16, color: subtitleColor), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('You will get a one-day trial class. Our team will contact you soon to schedule your session.', style: TextStyle(fontSize: 14, color: subtitleColor), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Note: This is a free trial request form, not a payment. All subscriptions are purchased through Apple In-App Purchase.', style: TextStyle(fontSize: 12, color: subtitleColor, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
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
