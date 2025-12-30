import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:rattil/models/package.dart' as models;
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/providers/revenuecat_provider.dart';
import 'package:rattil/screens/subscriber_dashboard_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PackageDetailScreen extends StatefulWidget {
  final models.Package package;
  const PackageDetailScreen({Key? key, required this.package}) : super(key: key);

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {

  @override
  void initState() {
    super.initState();
    debugPrint('📦 [PackageDetailScreen] Initializing for package: ${widget.package.name} (ID: ${widget.package.id})');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🚀 [PackageDetailScreen] Starting RevenueCat provider...');
      context.read<RevenueCatProvider>().start();
    });
  }

  /// Purchase a package using RevenueCat (Apple In-App Purchase - IAP only)
  /// All purchases/subscriptions use Apple IAP via RevenueCat SDK
  Future<void> _purchasePackage(BuildContext context) async {
    debugPrint('🛒 [PackageDetailScreen] ========== PURCHASE FLOW STARTED ==========');
    debugPrint('📋 [PackageDetailScreen] Package details:');
    debugPrint('   - Name: ${widget.package.name}');
    debugPrint('   - ID: ${widget.package.id}');
    debugPrint('   - Price: \$${widget.package.price}');
    
    final revenueCat = context.read<RevenueCatProvider>();
    debugPrint('⏳ [PackageDetailScreen] Initiating purchase...');
    if (revenueCat.offerings?.current == null) {
      await revenueCat.refreshOfferings();
    }
    final productId = widget.package.productId;
    final rcPackage = revenueCat.offerings?.current?.availablePackages.firstWhere(
      (pkg) => pkg.storeProduct.identifier == productId,
      orElse: () => revenueCat.offerings!.current!.availablePackages.isNotEmpty
        ? revenueCat.offerings!.current!.availablePackages.first
        : throw StateError('No available packages'),
    );
    if (rcPackage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not available. Please check your connection and try again.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
        ),
      );
      return;
    }
    if (revenueCat.hasAccess) {
      final currentSubscribedId = revenueCat.customerInfo?.entitlements.active[RevenueCatProvider.entitlementId]?.productIdentifier;
      if (currentSubscribedId != null && currentSubscribedId != productId) {
        if (!mounted) return;
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final isDarkMode = themeProvider.isDarkMode;
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) {
            final dialogBg = isDarkMode ? const Color(0xFF1F2937) : Colors.white;
            final textColor = isDarkMode ? Colors.white : const Color(0xFF111827);
            final subtitleColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
            final tealIcon = const Color(0xFF0d9488);
            final tealBg = isDarkMode ? const Color(0xFF0f766e).withOpacity(0.2) : const Color(0xFFccfbf1);
            final tealBorder = isDarkMode ? const Color(0xFF5eead4) : const Color(0xFF5eead4);
            final tealText = isDarkMode ? const Color(0xFF5eead4) : const Color(0xFF0f766e);
            return AlertDialog(
              backgroundColor: dialogBg,
              title: Text('Switch Package?', style: TextStyle(color: textColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You are currently subscribed to another package.', style: TextStyle(color: textColor)),
                  const SizedBox(height: 12),
                  Text('Purchasing this package will:', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Row(children: [Icon(Icons.arrow_forward, size: 16, color: tealIcon), const SizedBox(width: 4), Expanded(child: Text('Replace your current subscription', style: TextStyle(color: textColor)))]),
                  Row(children: [Icon(Icons.arrow_forward, size: 16, color: tealIcon), const SizedBox(width: 4), Expanded(child: Text('Cancel your existing package', style: TextStyle(color: textColor)))]),
                  Row(children: [Icon(Icons.arrow_forward, size: 16, color: tealIcon), const SizedBox(width: 4), Expanded(child: Text('Activate this package immediately', style: TextStyle(color: textColor)))]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: tealBg, borderRadius: BorderRadius.circular(4), border: Border.all(color: tealBorder, width: 1)),
                    child: Text('Note: You can only have one active package at a time.', style: TextStyle(fontWeight: FontWeight.bold, color: tealText, fontSize: 12)),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: subtitleColor))),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0d9488), foregroundColor: Colors.white), child: const Text('Switch Package')),
              ],
            );
          },
        );
        if (shouldProceed != true) return;
      }
    }
    final customerInfo = await revenueCat.purchasePackage(rcPackage);
    if (!mounted) return;
    if (revenueCat.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(revenueCat.errorMessage!),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
        ),
      );
    } else if (customerInfo != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Subscription activated! Welcome to Rattil.', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF0d9488),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [PackageDetailScreen] Building UI for package: ${widget.package.name}');
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF111827) : Colors.white;
    final appBarColor = isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final detailBoxBg = isDarkMode ? const Color(0xFF374151) : const Color(0xFFF9FAFB);
    List<Color> gradient;
    switch (widget.package.name) {
      case 'Premium Intensive':
        gradient = [Color(0xFFFFE0B2), Color(0xFFFFA726)]; // Soft Orange to Amber
        break;
      case 'Intermediate':
        gradient = [Color(0xFF3949AB), Color(0xFF90CAF9)]; // Indigo to Light Blue
        break;
      case 'Basic Recitation':
        gradient = [Color(0xFFA5D6A7), Color(0xFF388E3C)]; // Light Green to Deep Green
        break;
      default:
        gradient = [Color(widget.package.colorGradientStart), Color(widget.package.colorGradientEnd)]; // Fallback
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Package Details', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        color: bgColor,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -64,
                    right: -64,
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -48,
                    left: -48,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: SvgPicture.asset(
                      'assets/icon/app_icon.svg',
                      width: 80,
                      height: 80,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(widget.package.name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text('\$${widget.package.price} / month', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF009688), fontFamily: 'Roboto', fontStyle: FontStyle.normal)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: detailBoxBg,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Color(0xFF009688), size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Duration', style: TextStyle(fontSize: 12, color: subtitleColor)),
                          Text(widget.package.duration, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.menu_book, color: Color(0xFF009688), size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Session Time', style: TextStyle(fontSize: 12, color: subtitleColor)),
                          Text(widget.package.time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text("What's Included:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 12),
            ...widget.package.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color(0xFF009688),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.check, color: Color.fromARGB(255, 255, 255, 255), size: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(feature, style: TextStyle(fontSize: 14, color: isDarkMode ? Color(0xFFd1d5db) : Color(0xFF374151))),
                ],
              ),
            )),
            const SizedBox(height: 24),
            // Subscribe button
            Consumer<RevenueCatProvider>(
              builder: (context, revenueCat, _) {
                final productId = widget.package.productId;
                final isThisPackageSubscribed = revenueCat.isProductSubscribed(productId);
                
                debugPrint('🔄 [PackageDetailScreen] Consumer rebuild - RevenueCat state:');
                debugPrint('   - Package: ${widget.package.name} (ID: ${widget.package.id})');
                debugPrint('   - Product ID: $productId');
                debugPrint('   - Is this package subscribed: $isThisPackageSubscribed');
                debugPrint('   - Subscribed product ID: ${revenueCat.subscribedProductId ?? "none"}');
                debugPrint('   - hasAccess (general): ${revenueCat.hasAccess}');
                debugPrint('   - isPurchasing: ${revenueCat.isPurchasing}');
                debugPrint('   - hasOfferings: ${revenueCat.offerings != null}');
                debugPrint('   - availablePackages: ${revenueCat.availablePackages.length}');
                
                // If user is subscribed to THIS specific package, show "Go to Dashboard" button
                if (isThisPackageSubscribed) {
                  debugPrint('✅ [PackageDetailScreen] User is subscribed to THIS package - showing "Go to Dashboard" button');
                  return SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        debugPrint('🏠 [PackageDetailScreen] "Go to Dashboard" button tapped - navigating to dashboard');
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SubscriberDashboardScreen(),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.ease,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF14b8a6), Color(0xFF0d9488)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Go to Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Subscribe button (user is NOT subscribed to this specific package)
                final isPurchasing = revenueCat.isPurchasing;
                debugPrint('🛒 [PackageDetailScreen] User is NOT subscribed to THIS package - showing Subscribe button');
                debugPrint('   - Button enabled: ${!isPurchasing}');
                return SizedBox(
                  width: double.infinity,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isPurchasing ? null : () => _purchasePackage(context),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.ease,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF14b8a6), Color(0xFF0d9488)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isPurchasing)
            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          else ...[
                            Text(
                              'Subscribe',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: Colors.white, size: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // NOTE: "Request Trial" is NOT a payment mechanism - it's just a form submission
            // All actual purchases/subscriptions use Apple In-App Purchase (IAP) via RevenueCat
            SizedBox(
              width: double.infinity,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final subject = Uri.encodeComponent('Rattil App Trial Request: ${widget.package.name}');
                  final body = Uri.encodeComponent('Hello,\n\nI would like to request a trial for the following package on Rattil App:\n\n'
                    'Package Name: ${widget.package.name}\n'
                    'Package ID: ${widget.package.id}\n'
                    'Price: ${widget.package.price}\n'
                    'Duration: ${widget.package.duration}\n'
                    'Session Time: ${widget.package.time}\n'
                    'Features: ${widget.package.features.join(", ")}\n\n'
                    'Requested on: ${DateTime.now().toLocal()}\n\n'
                    'Thank you!');
                  final mailtoUrl = 'mailto:fareedstock@gmail.com?subject=$subject&body=$body';
                  if (await canLaunchUrl(Uri.parse(mailtoUrl))) {
                    await launchUrl(Uri.parse(mailtoUrl));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open email app. Please send your request to fareedstock@gmail.com.'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Request Trial', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Restore Purchases Button
            Consumer<RevenueCatProvider>(
              builder: (context, revenueCat, _) {
                final isRestoring = revenueCat.isRestoringPurchases;
                return SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: isRestoring
                        ? null
                        : () async {
                            revenueCat.setIsRestoringPurchases(true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Restoring purchases...'),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                              ),
                            );
                            final result = await revenueCat.restorePurchases();
                            revenueCat.setIsRestoringPurchases(false);
                            if (result == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Purchases restored successfully!'),
                                  backgroundColor: Color(0xFF0d9488),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('No purchases found or restore failed.'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                                ),
                              );
                            }
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF0d9488),
                    ),
                    child: isRestoring
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Color(0xFF0d9488),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text('Restore Purchases'),
                  ),
                );
              },
            ),
            // Terms of Use and Privacy Policy Links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    launchUrl(Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'));
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF0d9488), // App relevant teal color
                  ),
                  child: Text('Terms of Use'),
                ),
                Text(' | ', style: TextStyle(color: Color(0xFF0d9488))), // Teal separator
                TextButton(
                  onPressed: () {
                    launchUrl(Uri.parse('https://docs.google.com/document/d/1mzfze5c8wibnWrzIAR3bHWwKkA0o_tIzkKsXaoFxflM/edit?pli=1&tab=t.0'));
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF0d9488), // App relevant teal color
                  ),
                  child: Text('Privacy Policy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
