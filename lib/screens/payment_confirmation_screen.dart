import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/providers/theme_provider.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userAvatarUrl;
  final String cardNumber;
  final String cardholderName;
  final Package package;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PaymentConfirmationScreen({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.userAvatarUrl,
    required this.cardNumber,
    required this.cardholderName,
    required this.package,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  String getMaskedCardNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 4) return '**** **** **** ****';
    String last4 = cleaned.substring(cleaned.length - 4);
    return '**** **** **** $last4';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final cardBg = isDarkMode ? Color(0xFF1F2937) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Color(0xFF111827);
    final subtitleColor = isDarkMode ? Color(0xFF9CA3AF) : Color(0xFF6B7280);
    final tealDark = Color(0xFF0d9488);

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF111827) : Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 2,
        title: Text('Confirm Payment', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: userAvatarUrl != null ? NetworkImage(userAvatarUrl!) : null,
                            child: userAvatarUrl == null ? Icon(Icons.person, color: subtitleColor) : null,
                            backgroundColor: cardBg,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                              Text(userEmail, style: TextStyle(fontSize: 14, color: subtitleColor)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Card Info
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cardholder Name', style: TextStyle(fontSize: 14, color: subtitleColor)),
                            Text(cardholderName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                            const SizedBox(height: 8),
                            Text('Card Number', style: TextStyle(fontSize: 14, color: subtitleColor)),
                            Text(getMaskedCardNumber(cardNumber), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Package Info
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Package', style: TextStyle(fontSize: 14, color: subtitleColor)),
                            Text(package.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                            const SizedBox(height: 8),
                            Text('Price', style: TextStyle(fontSize: 14, color: subtitleColor)),
                            Text('\$${package.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tealDark)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Confirmation Prompt
                      Text('Are you sure you want to confirm this payment?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      // Buttons
                      AnimatedContainer(
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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onConfirm,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Confirm Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.ease,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onCancel,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
