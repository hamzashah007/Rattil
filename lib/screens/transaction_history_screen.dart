import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/utils/theme_colors.dart';
import 'package:rattil/utils/firestore_helpers.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please sign in to view transaction history';
        });
        return;
      }

      final transactions = await FirestoreHelpers.getUserTransactions(user.uid);
      
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load transactions. Please try again.';
      });
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '—';
    
    try {
      DateTime date;
      if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return '—';
      }
      
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return '—';
    }
  }

  String _formatAmount(double amount, String currency) {
    try {
      // Use NumberFormat.currency for proper formatting
      // This handles thousand separators, decimal places, and currency symbols
      final formatter = NumberFormat.currency(
        symbol: '', // We'll add currency code separately
        decimalDigits: 2,
        locale: _getLocaleForCurrency(currency),
      );
      
      // Format the amount
      final formatted = formatter.format(amount);
      
      // Add currency code at the end (e.g., "1,234.56 PKR")
      return '+$formatted $currency';
    } catch (e) {
      // Fallback to simple formatting if currency formatting fails
      debugPrint('Error formatting currency: $e');
      final formattedAmount = amount.toStringAsFixed(2);
      return '+$formattedAmount $currency';
    }
  }

  /// Get locale for currency formatting
  /// This ensures proper number formatting (thousand separators, decimal points)
  String _getLocaleForCurrency(String currency) {
    // Map common currencies to their locales for proper formatting
    switch (currency.toUpperCase()) {
      case 'PKR':
        return 'en_PK'; // Pakistan
      case 'USD':
        return 'en_US'; // United States
      case 'GBP':
        return 'en_GB'; // United Kingdom
      case 'EUR':
        return 'en_IE'; // Eurozone
      case 'AED':
        return 'en_AE'; // UAE
      case 'SAR':
        return 'en_SA'; // Saudi Arabia
      case 'INR':
        return 'en_IN'; // India
      default:
        return 'en_US'; // Default to US formatting
    }
  }

  String _getStatusFromTransaction(Map<String, dynamic> transaction) {
    final status = transaction['status'] as String?;
    if (status == null) return 'Completed';
    
    switch (status.toLowerCase()) {
      case 'active':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return ThemeColors.primaryTeal;
      case 'Cancelled':
      case 'Expired':
        return ThemeColors.yellowBadge;
      case 'Refunded':
      case 'Failed':
        return ThemeColors.redLogout;
      default:
        return ThemeColors.darkSubtitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDarkMode ? ThemeColors.darkBg : ThemeColors.lightBg;
    final cardColor = isDarkMode ? ThemeColors.darkCard : ThemeColors.lightCard;
    final textColor = isDarkMode ? ThemeColors.darkText : ThemeColors.lightText;
    final subtextColor = isDarkMode ? ThemeColors.darkSubtitle : ThemeColors.lightSubtitle;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Text('Transaction History', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: ThemeColors.primaryTeal,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: subtextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          onPressed: _loadTransactions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeColors.primaryTeal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _transactions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: subtextColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your purchase history will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: subtextColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      color: ThemeColors.primaryTeal,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, i) {
                          final tx = _transactions[i];
                          final packageName = tx['packageName'] as String? ?? 'Unknown Package';
                          final purchaseDate = tx['purchaseDate'];
                          final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                          final currency = tx['currency'] as String? ?? 'USD';
                          final status = _getStatusFromTransaction(tx);
                          final statusColor = _getStatusColor(status);

                          return Card(
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 18,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    packageName,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDate(purchaseDate),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: subtextColor,
                                    ),
                                  ),
                                  if (tx['expiryDate'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Expires: ${_formatDate(tx['expiryDate'])}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subtextColor,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatAmount(amount, currency),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status,
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
                    ),
    );
  }
}
