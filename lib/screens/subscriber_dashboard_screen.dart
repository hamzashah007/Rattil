import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/revenuecat_provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/utils/constants.dart';
import 'package:rattil/widgets/package_card.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:intl/intl.dart';

class SubscriberDashboardScreen extends StatefulWidget {
  const SubscriberDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SubscriberDashboardScreen> createState() => _SubscriberDashboardScreenState();
}

class _SubscriberDashboardScreenState extends State<SubscriberDashboardScreen> {
  bool _hasCheckedAccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Refresh customer info to get latest subscription status
      context.read<RevenueCatProvider>().refreshCustomerInfo();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check access after dependencies are available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final revenueCat = context.read<RevenueCatProvider>();
      if (!_hasCheckedAccess && !revenueCat.hasAccess) {
        _hasCheckedAccess = true;
        debugPrint('⚠️ [SubscriberDashboardScreen] Subscription cancelled - navigating to home');
        // Navigate to home screen if subscription is cancelled
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  Widget _buildSubscribedPackageCard(BuildContext context, RevenueCatProvider revenueCat, bool isDarkMode) {
    if (!revenueCat.hasAccess) {
      return const SizedBox.shrink();
    }
    final subscribedProductId = revenueCat.subscribedProductId;
    if (subscribedProductId == null) {
      return const SizedBox.shrink();
    }
    final subscribedPackage = packages.where((pkg) => pkg.productId == subscribedProductId).toList().isNotEmpty
      ? packages.firstWhere((pkg) => pkg.productId == subscribedProductId)
      : null;
    if (subscribedPackage == null) {
      return const SizedBox.shrink();
    }

    // Build subscription details widget
    final entitlement = revenueCat.customerInfo?.entitlements.active[RevenueCatProvider.entitlementId];
    final textColor = isDarkMode ? AppConstants.textColorDark : AppConstants.textColor;
    final subtitleColor = isDarkMode ? AppConstants.subtitleColorDark : AppConstants.subtitleColor;
    final detailBoxBg = isDarkMode ? AppConstants.detailBoxBgDark : AppConstants.detailBoxBg;

    // Format dates
    String formatDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return '—';
      try {
        // RevenueCat dates are in ISO 8601 format
        final date = DateTime.parse(dateString);
        return DateFormat('MMM dd, yyyy').format(date);
      } catch (e) {
        return dateString; // Return original if parsing fails
      }
    }

    final subscriptionDetailsWidget = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: detailBoxBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subscription Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (entitlement != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Purchased',
              value: formatDate(entitlement.latestPurchaseDate),
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Expires',
              value: formatDate(entitlement.expirationDate),
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Will renew',
              value: entitlement.willRenew ? 'Yes' : 'No',
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            // Show cancellation warning if subscription is cancelled
            if (!entitlement.willRenew) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFccfbf1), // Teal-100 (light teal background)
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF5eead4), width: 1.5), // Teal-300 (teal border)
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: const Color(0xFF0d9488), size: 20), // Teal-600 (app primary color)
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subscription Cancelled',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0f766e), // Teal-700 (dark teal for text)
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entitlement.expirationDate != null && entitlement.expirationDate!.isNotEmpty
                                ? 'Your subscription will remain active until ${formatDate(entitlement.expirationDate)}. You will lose access after that date.'
                                : 'Your subscription has been cancelled. Access will end when the current billing period expires.',
                            style: TextStyle(
                              color: const Color(0xFF134e4a), // Teal-800 (darker teal for body text)
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );

    return PackageCard(
      package: subscribedPackage,
      delay: 0,
      hasAccess: revenueCat.hasAccess,
      primaryButtonLabel: 'View PDF Material',
      secondaryButtonLabel: 'Customer Center',
      onPrimaryButtonTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PDFViewerScreen(),
          ),
        );
      },
      onSecondaryButtonTap: revenueCat.isPurchasing
          ? null
          : () => revenueCat.openCustomerCenter(),
      isLoading: false,
      isDashboardMode: true,
      subscriptionDetailsWidget: subscriptionDetailsWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF111827) : Colors.white;
    final appBarColor = isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111827);

    return Consumer<RevenueCatProvider>(
      builder: (context, revenueCat, child) {
        // Check if subscription is cancelled and navigate to home
        if (!revenueCat.hasAccess && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint('⚠️ [SubscriberDashboardScreen] No access detected - navigating to home');
            Navigator.of(context).popUntil((route) => route.isFirst);
          });
        }
        
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: appBarColor,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
            title: Text('Subscriber Dashboard', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ),
          body: Container(
            color: bgColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle
                  Center(
                    child: Text(
                      'Manage your subscription and access',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Subscribed Package Card (includes subscription details)
                  _buildSubscribedPackageCard(context, revenueCat, isDarkMode),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color subtitleColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class PDFViewerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final appBarColor = isDarkMode ? AppConstants.cardBgDark : AppConstants.cardBg;
    final textColor = isDarkMode ? AppConstants.textColorDark : AppConstants.textColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Material', style: TextStyle(color: textColor)),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SfPdfViewer.asset('assets/pdf/rattil_app_testing.pdf'),
    );
  }
}
