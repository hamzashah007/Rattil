import 'package:flutter/material.dart';
import 'package:rattil/models/package.dart' as models;

class SubscriptionInfoDialog extends StatelessWidget {
  final models.Package package;
  final VoidCallback onConfirm;
  final bool isSwitch;
  final String? currentPackageName;

  const SubscriptionInfoDialog({
    Key? key,
    required this.package,
    required this.onConfirm,
    this.isSwitch = false,
    this.currentPackageName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final dialogBg = isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final tealIcon = const Color(0xFF0d9488);
    final tealBg = isDarkMode ? const Color(0xFF0f766e).withOpacity(0.2) : const Color(0xFFccfbf1);
    final tealBorder = isDarkMode ? const Color(0xFF5eead4) : const Color(0xFF5eead4);
    final tealText = isDarkMode ? const Color(0xFF5eead4) : const Color(0xFF0f766e);

    return AlertDialog(
      backgroundColor: dialogBg,
      title: Text(
        isSwitch ? 'Switch Package?' : 'Subscription Details',
        style: TextStyle(color: textColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSwitch && currentPackageName != null)
            Text(
              'You are currently subscribed to $currentPackageName.',
              style: TextStyle(color: textColor),
            ),
          if (isSwitch) const SizedBox(height: 12),
          Text(
            'You are about to subscribe to:',
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            package.name,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tealText),
          ),
          const SizedBox(height: 8),
          Text('Price: \$${package.price}', style: TextStyle(color: textColor)),
          Text('Duration: ${package.duration}', style: TextStyle(color: textColor)),
          const SizedBox(height: 8),
          Text(
            'This is an auto-renewing subscription. You will be charged automatically unless you cancel at least 24 hours before the end of the current period.',
            style: TextStyle(fontSize: 13, color: subtitleColor),
          ),
          const SizedBox(height: 8),
          Text(
            'By confirming, you agree to the Terms of Use and Privacy Policy.',
            style: TextStyle(fontSize: 12, color: subtitleColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tealBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: tealBorder, width: 1),
            ),
            child: Text(
              isSwitch
                  ? 'Note: You can only have one active package at a time. Switching will replace your current subscription.'
                  : 'Note: You can only have one active package at a time.',
              style: TextStyle(fontWeight: FontWeight.bold, color: tealText, fontSize: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: subtitleColor)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0d9488),
            foregroundColor: Colors.white,
          ),
          child: Text(isSwitch ? 'Switch Package' : 'Subscribe'),
        ),
      ],
    );
  }
}
