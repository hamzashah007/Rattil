import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:rattil/models/package.dart' as models;
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/providers/revenuecat_provider.dart';
import 'package:rattil/screens/trial_request_success_screen.dart';
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
    
    // Note: RevenueCatProvider.isPurchasing is automatically set by purchasePackage()
    // No need to set local state
    debugPrint('⏳ [PackageDetailScreen] Initiating purchase...');
    
    // Ensure offerings are loaded
    debugPrint('🔍 [PackageDetailScreen] Checking offerings availability...');
    if (revenueCat.offerings?.current == null) {
      debugPrint('⚠️  [PackageDetailScreen] Offerings not loaded, fetching now...');
      await revenueCat.refreshOfferings();
      debugPrint('✅ [PackageDetailScreen] Offerings refresh completed');
    } else {
      debugPrint('✅ [PackageDetailScreen] Offerings already loaded');
      debugPrint('   - Current offering ID: ${revenueCat.offerings?.current?.identifier}');
      debugPrint('   - Available packages: ${revenueCat.offerings?.current?.availablePackages.length ?? 0}');
    }

    // Map package name to correct productId
    String productId;
    switch (widget.package.name) {
      case 'Basic Recitation':
        productId = 'basic01';
        break;
      case 'Intermediate':
        productId = 'intermediate02';
        break;
      case 'Premium Intensive':
        productId = 'premium03';
        break;
      default:
        productId = widget.package.id.toString().padLeft(2, '0');
    }
    debugPrint('🔎 [PackageDetailScreen] Matching package to RevenueCat product...');
    debugPrint('   - Package: ${widget.package.name} (ID: ${widget.package.id})');
    debugPrint('   - Looking for product ID: $productId');
    
    // First, check if product exists in offerings (diagnostic)
    final productExists = revenueCat.isProductInOfferings(productId);
    debugPrint('   - Product exists in offerings: $productExists');
    
    final rcPackage = revenueCat.findPackageByStoreProductId(productId);

    if (rcPackage == null) {
      debugPrint('❌ [PackageDetailScreen] Package NOT FOUND in RevenueCat offerings!');
      debugPrint('   - Package Name: ${widget.package.name}');
      debugPrint('   - Package ID: ${widget.package.id}');
      debugPrint('   - Searched product ID: $productId');
      debugPrint('   - Available packages: ${revenueCat.availablePackages.length}');
      if (revenueCat.availablePackages.isNotEmpty) {
        debugPrint('   - Available product IDs in RevenueCat:');
        for (final pkg in revenueCat.availablePackages) {
          debugPrint('     • Product ID: ${pkg.storeProduct.identifier}');
          debugPrint('       - Package ID: ${pkg.identifier}');
          debugPrint('       - Title: ${pkg.storeProduct.title}');
          debugPrint('       - Price: ${pkg.storeProduct.priceString}');
        }
      } else {
        debugPrint('   ⚠️ No packages available in RevenueCat offerings!');
        debugPrint('   💡 This might indicate:');
        debugPrint('      1. RevenueCat offerings not loaded properly');
        debugPrint('      2. Product not configured in RevenueCat dashboard');
        debugPrint('      3. Product not configured in App Store Connect');
        debugPrint('      4. Network connectivity issue');
      }
      if (!mounted) {
        debugPrint('⚠️  [PackageDetailScreen] Widget not mounted, aborting...');
        return;
      }
      // Note: RevenueCatProvider.isPurchasing is automatically cleared by purchasePackage()
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.package.id == 3 
              ? 'Premium Intensive package not found in RevenueCat. Please check RevenueCat dashboard configuration.'
              : 'Product not available. Please check your connection and try again.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
        ),
      );
      debugPrint('🛑 [PackageDetailScreen] ========== PURCHASE FLOW ABORTED ==========');
      return;
    }

    debugPrint('✅ [PackageDetailScreen] Package matched successfully!');
    debugPrint('   - RevenueCat Package ID: ${rcPackage.identifier}');
    debugPrint('   - Store Product ID: ${rcPackage.storeProduct.identifier}');
    debugPrint('   - Product Title: ${rcPackage.storeProduct.title}');
    debugPrint('   - Product Price: ${rcPackage.storeProduct.priceString}');
    debugPrint('   - Package Type: ${rcPackage.packageType}');

    // Check if user already has a subscription to a different package
    if (revenueCat.hasAccess) {
      final currentSubscribedId = revenueCat.subscribedProductId;
      // Use the same mapping for current productId
      String currentProductId;
      switch (widget.package.name) {
        case 'Basic Recitation':
          currentProductId = 'basic01';
          break;
        case 'Intermediate':
          currentProductId = 'intermediate02';
          break;
        case 'Premium Intensive':
          currentProductId = 'premium03';
          break;
        default:
          currentProductId = widget.package.id.toString().padLeft(2, '0');
      }
      // If user is trying to purchase a different package
      if (currentSubscribedId != null && currentSubscribedId != productId) {
        debugPrint('⚠️ [PackageDetailScreen] User has different subscription - showing warning dialog');
        
        // Find current package name for better messaging
        String currentPackageName = 'your current package';
        try {
          final currentPackageIdInt = int.parse(currentSubscribedId);
          final currentPkg = models.packages.firstWhere(
            (pkg) => pkg.id == currentPackageIdInt,
            orElse: () => models.packages.first,
          );
          currentPackageName = currentPkg.name;
        } catch (e) {
          debugPrint('⚠️ Could not find current package name: $e');
        }
        
        // Show warning dialog
        if (!mounted) return;
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final isDarkMode = themeProvider.isDarkMode;
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) {
            // Dialog colors for dark/light mode
            final dialogBg = isDarkMode ? const Color(0xFF1F2937) : Colors.white;
            final textColor = isDarkMode ? Colors.white : const Color(0xFF111827);
            final subtitleColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
            final tealIcon = const Color(0xFF0d9488); // Teal-600 (app primary)
            final tealBg = isDarkMode ? const Color(0xFF0f766e).withOpacity(0.2) : const Color(0xFFccfbf1); // Teal-100/700 with opacity
            final tealBorder = isDarkMode ? const Color(0xFF5eead4) : const Color(0xFF5eead4); // Teal-300
            final tealText = isDarkMode ? const Color(0xFF5eead4) : const Color(0xFF0f766e); // Teal-300/700
            
            return AlertDialog(
              backgroundColor: dialogBg,
              title: Text(
                'Switch Package?',
                style: TextStyle(color: textColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are currently subscribed to $currentPackageName.',
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Purchasing this package will:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.arrow_forward, size: 16, color: tealIcon),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Replace your current subscription',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.arrow_forward, size: 16, color: tealIcon),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Cancel your existing package',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.arrow_forward, size: 16, color: tealIcon),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Activate this package immediately',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tealBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: tealBorder, width: 1),
                    ),
                    child: Text(
                      'Note: You can only have one active package at a time.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tealText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: subtitleColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0d9488),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Switch Package'),
                ),
              ],
            );
          },
        );
        
        if (shouldProceed != true) {
          debugPrint('🚫 [PackageDetailScreen] User cancelled package switch');
          return; // User cancelled
        }
        debugPrint('✅ [PackageDetailScreen] User confirmed package switch');
      }
    }

    // Purchase using the package directly (best practice)
    debugPrint('💳 [PackageDetailScreen] Initiating purchase with RevenueCat...');
    debugPrint('   - Calling purchasePackage()...');

    bool didTimeout = false;
    final purchaseFuture = revenueCat.purchasePackage(rcPackage);
    final customerInfo = await purchaseFuture.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        didTimeout = true;
        return null;
      },
    );

    if (didTimeout) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Purchase timed out. Please check your connection and try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
          ),
        );
      }
      return;
    }

    debugPrint('📥 [PackageDetailScreen] Purchase call completed');
    
    if (!mounted) {
      debugPrint('⚠️  [PackageDetailScreen] Widget not mounted after purchase, aborting...');
      return;
    }

    if (revenueCat.errorMessage != null) {
      debugPrint('❌ [PackageDetailScreen] Purchase FAILED with error:');
      debugPrint('   - Error: ${revenueCat.errorMessage}');
      // Note: RevenueCatProvider.isPurchasing is automatically cleared by purchasePackage()
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(revenueCat.errorMessage!),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
        ),
      );
      debugPrint('🛑 [PackageDetailScreen] ========== PURCHASE FLOW FAILED ==========');
    } else if (customerInfo != null) {
      debugPrint('✅ [PackageDetailScreen] Purchase completed successfully!');
      debugPrint('   - Customer Info received');
      debugPrint('   - Checking entitlement access...');
      
      final productId = widget.package.id.toString().padLeft(2, '0');
      
      // Retry mechanism: Wait for subscription status to sync
      // Keep purchasing state active until subscription is confirmed
      bool subscriptionActive = false;
      
      // OPTIMIZED: Check immediately using temporary storage (no refresh needed)
      // Temporary storage is set immediately in purchasePackage(), so UI should update instantly
      debugPrint('   - Checking subscription status immediately (using temporary storage)...');
      
      // Check immediately without refresh (temporary storage should be available)
      final hasAccessImmediate = revenueCat.hasAccess;
      final isThisPackageSubscribedImmediate = revenueCat.isProductSubscribed(productId);
      debugPrint('   - Immediate check: Has access: $hasAccessImmediate, Is subscribed: $isThisPackageSubscribedImmediate');
      
      if (hasAccessImmediate && isThisPackageSubscribedImmediate) {
        subscriptionActive = true;
        debugPrint('   ✅ Subscription status confirmed immediately (using temporary storage)!');
      } else {
        // If not confirmed, refresh and retry with shorter delays (optimized for Premium Intensive)
        debugPrint('   - Temporary storage not working, refreshing customer info...');
        await revenueCat.refreshCustomerInfo();
        
        // Check again after refresh
        final hasAccessAfterRefresh = revenueCat.hasAccess;
        final isThisPackageSubscribedAfterRefresh = revenueCat.isProductSubscribed(productId);
        debugPrint('   - After refresh: Has access: $hasAccessAfterRefresh, Is subscribed: $isThisPackageSubscribedAfterRefresh');
        
        if (hasAccessAfterRefresh && isThisPackageSubscribedAfterRefresh) {
          subscriptionActive = true;
          debugPrint('   ✅ Subscription status confirmed after refresh!');
        } else {
          // Final retry with minimal delays (optimized for faster UI update)
          for (int attempt = 1; attempt < 2; attempt++) {
            debugPrint('   - Final retry attempt ${attempt + 1}/2, waiting for sync...');
            await Future.delayed(Duration(milliseconds: 100 * attempt)); // 100ms (reduced from 200ms)
            
            // Refresh customer info to get latest status
            await revenueCat.refreshCustomerInfo();
            
            final hasAccess = revenueCat.hasAccess;
            final isThisPackageSubscribed = revenueCat.isProductSubscribed(productId);
            
            debugPrint('   - Attempt ${attempt + 1}: Has access: $hasAccess, Is subscribed: $isThisPackageSubscribed');
            
            if (hasAccess && isThisPackageSubscribed) {
              subscriptionActive = true;
              debugPrint('   ✅ Subscription status confirmed!');
              break;
            }
          }
        }
      }
      
      if (subscriptionActive) {
        debugPrint('🎉 [PackageDetailScreen] Entitlement is ACTIVE!');
        debugPrint('   - User now has access to Rattil Packages');
        await revenueCat.refreshCustomerInfo();
        // Removed setState(); rely on Provider notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Subscription activated! Welcome to Rattil.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF0d9488),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
            ),
          );
        }
        debugPrint('✅ [PackageDetailScreen] ========== PURCHASE FLOW SUCCESS ==========');
        // Navigation removed, user stays on this screen
      } else {
        debugPrint('⚠️  [PackageDetailScreen] Purchase completed but subscription status not confirmed after retries');
        debugPrint('   - This might be normal if entitlement is pending activation');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Purchase completed! Your subscription will be activated shortly.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
            ),
          );
        }
        // Navigation removed here as well
      }
    } else {
      debugPrint('⚠️  [PackageDetailScreen] Purchase returned null customerInfo');
      debugPrint('   - User may have cancelled the purchase');
      // Note: RevenueCatProvider.isPurchasing is automatically cleared by purchasePackage()
      debugPrint('🛑 [PackageDetailScreen] ========== PURCHASE FLOW CANCELLED ==========');
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
                // Map package name to correct productId
                String productId;
                switch (widget.package.name) {
                  case 'Basic Recitation':
                    productId = 'basic01';
                    break;
                  case 'Intermediate':
                    productId = 'intermediate02';
                    break;
                  case 'Premium Intensive':
                    productId = 'premium03';
                    break;
                  default:
                    productId = widget.package.id.toString().padLeft(2, '0');
                }
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
                onTap: () {
                  // This is NOT a payment - just a trial request form submission
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrialRequestSuccessScreen(
                        package: widget.package,
                      ),
                    ),
                  );
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
                final isRestoring = revenueCat.isRestoringPurchases ?? false;
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
