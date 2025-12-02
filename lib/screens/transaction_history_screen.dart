import 'package:flutter/material.dart';
import 'package:rattil/utils/theme_colors.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final bool isDarkMode;
  const TransactionHistoryScreen({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? ThemeColors.darkBg : ThemeColors.lightBg;
    final cardColor = isDarkMode ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
    final subtextColor = isDarkMode ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;

    // Example transaction data
    final transactions = [
      {
        'title': 'Premium Intensive',
        'date': '2025-11-28',
        'amount': '+18.00 USD',
        'status': 'Completed',
      },
      {
        'title': 'Basic Recitation',
        'date': '2025-10-15',
        'amount': '+10.00 USD',
        'status': 'Completed',
      },
      {
        'title': 'Intermediate',
        'date': '2025-09-02',
        'amount': '+14.00 USD',
        'status': 'Pending',
      },
      {
        'title': 'Refund',
        'date': '2025-08-20',
        'amount': '-10.00 USD',
        'status': 'Failed',
      },
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Text('Transaction History', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final tx = transactions[i];
          Color statusColor;
          switch (tx['status']) {
            case 'Completed':
              statusColor = ThemeColors.primaryTeal;
              break;
            case 'Pending':
              statusColor = ThemeColors.yellowBadge;
              break;
            case 'Failed':
              statusColor = ThemeColors.redLogout;
              break;
            default:
              statusColor = subtextColor;
          }
          return Card(
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx['title']!, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 6),
                  Text(tx['date']!, style: TextStyle(fontSize: 14, color: subtextColor)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tx['amount']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tx['status']!,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
