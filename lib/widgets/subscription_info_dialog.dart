import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../models/package.dart' as models;

/// Subscription information dialog that displays subscription terms
/// Required by Apple Guideline 3.1.2 for auto-renewable subscriptions
/// Shows: price, duration, auto-renewal info, and cancellation instructions
class SubscriptionInfoDialog extends StatelessWidget {
  final models.Package package;
  final VoidCallback onConfirm;

  const SubscriptionInfoDialog({
    Key? key,
    required this.package,
    required this.onConfirm,
  }) : super(key: key);

  /// Launch URL in external browser
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('⚠️ Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Colors for dark/light mode
    final dialogBg = isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final tealPrimary = const Color(0xFF0d9488); // Teal-600
    final tealBg = isDarkMode 
        ? const Color(0xFF0f766e).withOpacity(0.2) 
        : const Color(0xFFccfbf1); // Teal-100/700 with opacity
    final tealBorder = const Color(0xFF5eead4); // Teal-300
    final dividerColor = isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.info_outline, color: tealPrimary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Subscription Information',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(package.colorGradientStart),
                    Color(package.colorGradientEnd),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${package.price.toStringAsFixed(2)} / month',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.duration,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 20),

            // Subscription terms
            Text(
              'Subscription Terms',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              Icons.autorenew,
              'Auto-Renewable',
              'This subscription automatically renews each month unless cancelled.',
              tealPrimary,
              textColor,
              subtitleColor,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              Icons.credit_card,
              'Payment',
              'You will be charged \$${package.price.toStringAsFixed(2)} per month through your App Store account.',
              tealPrimary,
              textColor,
              subtitleColor,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              Icons.event_repeat,
              'Renewal',
              'Your subscription will automatically renew 24 hours before the end of each billing period.',
              tealPrimary,
              textColor,
              subtitleColor,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              Icons.cancel,
              'Cancellation',
              'You can cancel anytime by managing your subscriptions in the App Store. Cancellation takes effect at the end of the current billing period.',
              tealPrimary,
              textColor,
              subtitleColor,
            ),

            const SizedBox(height: 20),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 20),

            // Important note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tealBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tealBorder, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: tealPrimary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Subscription',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Go to Settings > [Your Name] > Subscriptions to view and manage your subscription.',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Terms & Privacy links - CLICKABLE (Apple Guideline 3.1.2 requirement)
            Column(
              children: [
                Text(
                  'By subscribing, you agree to our:',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => _launchURL('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
                      child: Text(
                        'Terms of Use (EULA)',
                        style: TextStyle(
                          color: tealPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                    InkWell(
                      onTap: () => _launchURL('https://docs.google.com/document/d/1mzfze5c8wibnWrzIAR3bHWwKkA0o_tIzkKsXaoFxflM/edit?pli=1&tab=t.0'),
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: tealPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: subtitleColor),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: tealPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Continue to Purchase'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String description,
    Color iconColor,
    Color titleColor,
    Color descriptionColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: descriptionColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
