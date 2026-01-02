import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/models/package.dart' as models;
import 'package:rattil/providers/packages_provider.dart';
import 'package:rattil/providers/theme_provider.dart';
import 'package:rattil/providers/drawer_provider.dart';
import 'package:rattil/utils/constants.dart';
import 'package:rattil/widgets/app_bar_widget.dart';
import 'package:rattil/widgets/curved_bottom_bar.dart';
import 'package:rattil/widgets/drawer_menu.dart';
import 'package:rattil/widgets/package_card.dart';
import 'package:rattil/providers/revenuecat_provider.dart';
import 'package:rattil/screens/profile_screen.dart';
import 'package:rattil/providers/auth_provider.dart';
import 'package:rattil/screens/subscriber_dashboard_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rattil/widgets/subscription_info_dialog.dart';

class PackagesScreen extends StatefulWidget {
  final bool showAppBar;
  const PackagesScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final int notificationCount = 2;

  void _onBottomBarTap(BuildContext context, int index) {
    final provider = Provider.of<PackagesProvider>(context, listen: false);
    if (provider.selectedIndex == index) return;
    if (index == 0 && Navigator.of(context).canPop()) {
      debugPrint('PackagesScreen: Home icon tapped, popping to HomeScreen');
      Navigator.pop(context);
      return;
    }
    provider.setSelectedIndex(index);
  }

  void _toggleDrawer(BuildContext context) {
    final drawerProvider = Provider.of<DrawerProvider>(context, listen: false);
    drawerProvider.setDrawerOpen(!drawerProvider.isDrawerOpen);
  }

  void _closeDrawer(BuildContext context) {
    Provider.of<DrawerProvider>(context, listen: false).closeDrawer();
  }

  void _toggleDarkMode(BuildContext context) {
    Provider.of<ThemeProvider>(context, listen: false).toggleDarkMode();
  }

  void _handleNavigation(BuildContext context, String route) {
    _closeDrawer(context);
  }

  void _handleLogout(BuildContext context) {
    _closeDrawer(context);
  }
  
  /// Show email collection dialog for guest subscribers
  Future<void> _showGuestEmailCollectionDialog(String productId) async {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Colors for dark/light mode
    final dialogBg = isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final infoBg = isDarkMode ? const Color(0xFF0f766e).withOpacity(0.2) : const Color(0xFFccfbf1);
    final infoBorder = isDarkMode ? const Color(0xFF5eead4) : const Color(0xFF14b8a6);
    final infoText = isDarkMode ? const Color(0xFF5eead4) : const Color(0xFF0f766e);
    
    return showDialog(
      context: context,
      barrierDismissible: false, // Must provide email
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text(
          'Welcome to Rattil',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        ),
        content: SizedBox(
          width: double.maxFinite, // Full width dialog
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To access Zoom classes and get full benefits, please provide your email:',
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    labelStyle: TextStyle(color: subtitleColor),
                    hintText: 'example@email.com',
                    hintStyle: TextStyle(color: subtitleColor.withOpacity(0.5)),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email, color: const Color(0xFF0d9488)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Name (Optional)',
                    labelStyle: TextStyle(color: subtitleColor),
                    hintText: 'Your Name',
                    hintStyle: TextStyle(color: subtitleColor.withOpacity(0.5)),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person, color: const Color(0xFF0d9488)),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: infoBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: infoBorder),
                  ),
                  child: Text(
                    'This will help us:\n• Add you to Zoom classes\n• Send important updates\n• Provide better support',
                    style: TextStyle(fontSize: 12, color: infoText),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You can provide your email later from Settings.'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(bottom: 60, left: 16, right: 16),
                ),
              );
            },
            child: Text(
              'Skip for Now',
              style: TextStyle(color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email address.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(bottom: 60, left: 16, right: 16),
                  ),
                );
                return;
              }
              
              try {
                // Save to Firestore
                await FirebaseFirestore.instance.collection('guest_subscribers').add({
                  'email': email,
                  'name': nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                  'mode': 'guest',
                  'productId': productId,
                  'subscribedAt': FieldValue.serverTimestamp(),
                  'platform': Theme.of(context).platform.toString(),
                });
                
                debugPrint('✅ [PackagesScreen] Guest subscriber email saved: $email');
                
                Navigator.pop(context);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thank you! We\'ll add you to Zoom classes soon.'),
                      backgroundColor: Color(0xFF0d9488),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('❌ [PackagesScreen] Error saving guest email: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving email. Please try again.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0d9488),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  List<models.Package> get filteredPackages {
    return models.packages;
  }

  @override
  void initState() {
    super.initState();
    debugPrint('📦 [PackagesScreen] Initializing PackagesScreen');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🚀 [PackagesScreen] Starting RevenueCat provider...');
      context.read<RevenueCatProvider>().start();
    });
  }

  /// Purchase a package using RevenueCat (Apple In-App Purchase - IAP only)
  /// All purchases/subscriptions use Apple IAP via RevenueCat SDK
  /// Best practices:
  /// 1. Get offerings (pre-fetched on app launch)
  /// 2. Find matching package from availablePackages dynamically
  /// 3. Purchase the package directly using Apple IAP
  Future<void> _purchasePackage(BuildContext context, int index, models.Package uiPackage) async {
    debugPrint('🛒 [PackagesScreen] ========== PURCHASE FLOW STARTED ==========');
    debugPrint('📋 [PackagesScreen] Package details:');
    debugPrint('   - Name: ${uiPackage.name}');
    debugPrint('   - ID: ${uiPackage.id}');
    debugPrint('   - Price: \$${uiPackage.price}');
    debugPrint('   - Index: $index');
    
    final revenueCat = context.read<RevenueCatProvider>();
    
    // Check if user already has a subscription to a different package
    if (revenueCat.hasAccess) {
      final currentSubscribedId = revenueCat.subscribedProductId;
      final productId = uiPackage.productId;
      
      // If user is trying to purchase a different package
      if (currentSubscribedId != null && currentSubscribedId != productId) {
        debugPrint('⚠️ [PackagesScreen] User has different subscription - showing warning dialog');
        
        // Find current package name for better messaging
        String currentPackageName = 'your current package';
        try {
          final currentPkg = models.packages.firstWhere(
            (pkg) => pkg.productId == currentSubscribedId,
            orElse: () => models.packages.first,
          );
          currentPackageName = currentPkg.name;
        } catch (e) {
          debugPrint('⚠️ Could not find current package name: $e');
        }
        
        // Show warning dialog
        if (!mounted) return;
        final parentContext = context; // Capture parent context for Provider
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final isDarkMode = themeProvider.isDarkMode;
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => SubscriptionInfoDialog(
            package: uiPackage,
            isSwitch: true,
            currentPackageName: currentPackageName,
            onConfirm: () async {
              await _completePurchase(uiPackage, index, parentContext); // Use parentContext here
            },
          ),
        );
        
        if (shouldProceed != true) {
          debugPrint('🚫 [PackagesScreen] User cancelled package switch');
          return; // User cancelled
        }
      }
    }
    
    // Ensure offerings are loaded
    debugPrint('🔍 [PackagesScreen] Checking offerings availability...');
    if (revenueCat.offerings?.current == null) {
      debugPrint('⚠️  [PackagesScreen] Offerings not loaded, fetching now...');
      await revenueCat.refreshOfferings();
      debugPrint('✅ [PackagesScreen] Offerings refresh completed');
    } else {
      debugPrint('✅ [PackagesScreen] Offerings already loaded');
      debugPrint('   - Current offering ID: ${revenueCat.offerings?.current?.identifier}');
      debugPrint('   - Available packages: ${revenueCat.offerings?.current?.availablePackages.length ?? 0}');
    }

    // Match UI package (id: 01, 02, 03) to RevenueCat package by store product identifier
    final productId = uiPackage.productId;
    debugPrint('🔎 [PackagesScreen] Matching package to RevenueCat product...');
    debugPrint('   - Looking for product ID: $productId');
    
    final rcPackage = revenueCat.findPackageByStoreProductId(productId);

    if (rcPackage == null) {
      debugPrint('❌ [PackagesScreen] Package NOT FOUND in RevenueCat offerings!');
      debugPrint('   - Package Name: ${uiPackage.name}');
      debugPrint('   - Package ID: ${uiPackage.id}');
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
        debugPrint('⚠️  [PackagesScreen] Widget not mounted, aborting...');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uiPackage.id == 3 
              ? 'Premium Intensive package not found in RevenueCat. Please check RevenueCat dashboard configuration.'
              : 'Product not available. Please check your connection and try again.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      debugPrint('🛑 [PackagesScreen] ========== PURCHASE FLOW ABORTED ==========');
      return;
    }

    debugPrint('✅ [PackagesScreen] Package matched successfully!');
    debugPrint('   - RevenueCat Package ID: ${rcPackage.identifier}');
    debugPrint('   - Store Product ID: ${rcPackage.storeProduct.identifier}');
    debugPrint('   - Product Title: ${rcPackage.storeProduct.title}');
    debugPrint('   - Product Price: ${rcPackage.storeProduct.priceString}');
    debugPrint('   - Package Type: ${rcPackage.packageType}');

    // Set purchasing state IMMEDIATELY to show loading UI
    debugPrint('⏳ [PackagesScreen] Setting purchasing state for index $index...');
    final packagesProvider = Provider.of<PackagesProvider>(context, listen: false);
    packagesProvider.setPurchasingIndex(index);
    // Force immediate UI update by scheduling a microtask
    await Future.microtask(() {});
    
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
      packagesProvider.clearPurchasingIndex();
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

    debugPrint('📥 [PackagesScreen] Purchase call completed');
    
    if (!mounted) {
      debugPrint('⚠️  [PackagesScreen] Widget not mounted after purchase, aborting...');
      return;
    }

    if (revenueCat.errorMessage != null) {
      debugPrint('❌ [PackagesScreen] Purchase FAILED with error:');
      debugPrint('   - Error: ${revenueCat.errorMessage}');
      // Clear purchasing state before showing error
      final packagesProvider = Provider.of<PackagesProvider>(context, listen: false);
      packagesProvider.clearPurchasingIndex();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(revenueCat.errorMessage!),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
        ),
      );
      debugPrint('🛑 [PackagesScreen] ========== PURCHASE FLOW FAILED ==========');
    } else if (customerInfo != null) {
      debugPrint('✅ [PackagesScreen] Purchase completed successfully!');
      debugPrint('   - Customer Info received');
      debugPrint('   - Checking entitlement access...');
      
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
        debugPrint('🎉 [PackagesScreen] Entitlement is ACTIVE!');
        debugPrint('   - User now has access to Rattil Packages');
        // Clear purchasing state immediately
        final packagesProvider = Provider.of<PackagesProvider>(context, listen: false);
        packagesProvider.clearPurchasingIndex();
        // Force RevenueCat provider to notify listeners for immediate UI update
        await revenueCat.refreshCustomerInfo();
        // Purchase successful and entitlement is active
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Subscription activated! Welcome to Rattil Packages.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF0d9488), // Teal color
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(
                bottom: 60, // Position lower on screen
                left: 16,
                right: 16,
              ),
            ),
          );
          
          // Check if user is in guest mode and show email collection dialog
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isGuest) {
            debugPrint('📧 [PackagesScreen] Guest user subscribed - showing email collection dialog');
            await Future.delayed(const Duration(milliseconds: 500)); // Small delay after success message
            if (mounted) {
              _showGuestEmailCollectionDialog(productId);
            }
          }
        }
        debugPrint('✅ [PackagesScreen] ========== PURCHASE FLOW SUCCESS ==========');
      } else {
        debugPrint('⚠️  [PackagesScreen] Purchase completed but subscription status not confirmed after retries');
        debugPrint('   - This might be normal if entitlement is pending activation');
        // Clear purchasing state even if not fully synced (but keep trying in background)
        final packagesProvider = Provider.of<PackagesProvider>(context, listen: false);
        packagesProvider.clearPurchasingIndex();
        // Show success message anyway since purchase was successful
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Purchase completed! Your subscription will be activated shortly.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(
                bottom: 60,
                left: 16,
                right: 16,
              ),
            ),
          );
        }
      }
    } else {
      debugPrint('⚠️  [PackagesScreen] Purchase returned null customerInfo');
      debugPrint('   - User may have cancelled the purchase');
      // Clear purchasing state on cancellation
      final packagesProvider = Provider.of<PackagesProvider>(context, listen: false);
      packagesProvider.clearPurchasingIndex();
      debugPrint('🛑 [PackagesScreen] ========== PURCHASE FLOW CANCELLED ==========');
    }
  }

  Future<void> _completePurchase(models.Package uiPackage, int index, BuildContext context) async {
    final revenueCat = context.read<RevenueCatProvider>();
    // Ensure offerings are loaded
    if (revenueCat.offerings?.current == null) {
      await revenueCat.refreshOfferings();
    }
    final productId = uiPackage.productId;
    final rcPackage = revenueCat.findPackageByStoreProductId(productId);
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
    final packagesProvider = Provider.of<PackagesProvider>(context, listen: false);
    packagesProvider.setPurchasingIndex(index);
    await Future.microtask(() {});
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
      packagesProvider.clearPurchasingIndex();
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
    if (!mounted) return;
    if (revenueCat.errorMessage != null) {
      packagesProvider.clearPurchasingIndex();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(revenueCat.errorMessage!),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
        ),
      );
      return;
    } else if (customerInfo != null) {
      packagesProvider.clearPurchasingIndex();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Subscription activated! Welcome to Rattil Packages.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF0d9488),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            bottom: 60,
            left: 16,
            right: 16,
          ),
        ),
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isGuest) {
        debugPrint('📧 [PackagesScreen] Guest user subscribed - showing email collection dialog');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _showGuestEmailCollectionDialog(uiPackage.productId);
        }
      }
    }
  }

  Widget _getScreenContent(BuildContext context) {
    final provider = Provider.of<PackagesProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Use Consumer to listen to RevenueCat changes for immediate UI updates
    return Consumer<RevenueCatProvider>(
      builder: (context, revenueCat, child) {

    debugPrint('🎨 [PackagesScreen] Building UI - Tab index: ${provider.selectedIndex}');
    debugPrint('   - isDarkMode: $isDarkMode');
    debugPrint('   - hasAccess: ${revenueCat.hasAccess}');
    debugPrint('   - isPurchasing: ${revenueCat.isPurchasing}');
    debugPrint('   - availablePackages: ${revenueCat.availablePackages.length}');
    
    if (provider.selectedIndex == 0) {
      debugPrint('🏠 [PackagesScreen] Showing Home Screen tab');
      return Center(child: Text('Home Screen', style: TextStyle(fontSize: 32)));
    } else if (provider.selectedIndex == 1) {
      debugPrint('📦 [PackagesScreen] Showing Packages tab');
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Our Packages',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppConstants.textColorDark : AppConstants.textColor,
                  letterSpacing: -1,
                  wordSpacing: 0,
                ),
              ),
            ),
          ),
          // Error message display
          if (revenueCat.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        revenueCat.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.red.shade700),
                      onPressed: () {
                        debugPrint('🔄 [PackagesScreen] Refresh button pressed - refreshing offerings and customer info');
                        revenueCat.refreshOfferings();
                        revenueCat.refreshCustomerInfo();
                      },
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: Color(0xFF0d9488),
              onRefresh: () async {
                debugPrint('[PackagesScreen] Pull-to-refresh triggered.');
                await revenueCat.refreshOfferings();
                await revenueCat.refreshCustomerInfo();
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 75),
                itemCount: filteredPackages.length + 2, // Add one for restore button at top, one for compliance widgets at bottom
                itemBuilder: (context, index) {
                  // First item: Restore Purchases button (prominent at top)
                  if (index == 0) {
                    // Restore Purchases button below app bar, above packages
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Consumer<RevenueCatProvider>(
                        builder: (context, revenueCat, _) {
                          final isRestoring = revenueCat.isRestoringPurchases;
                          return GestureDetector(
                            onTap: isRestoring
                                ? null
                                : () async {
                                    debugPrint('🔄 [PackagesScreen] ========== RESTORE PURCHASES TAPPED ==========');
                                    debugPrint('👆 [PackagesScreen] User tapped Restore Purchases button');
                                    debugPrint('⏱️ [PackagesScreen] Timestamp: ${DateTime.now()}');
                                    debugPrint('🚀 [PackagesScreen] Setting isRestoringPurchases = true');
                                    revenueCat.setIsRestoringPurchases(true);
                                    try {
                                      debugPrint('📞 [PackagesScreen] Calling revenueCat.restorePurchases()...');
                                      final info = await revenueCat.restorePurchases();
                                      debugPrint('✅ [PackagesScreen] restorePurchases() call completed');
                                      debugPrint('📊 [PackagesScreen] Result: ${info != null ? "CustomerInfo received" : "null (cancelled or no purchases)"}');
                                      if (!mounted) {
                                        debugPrint('⚠️ [PackagesScreen] Widget not mounted, skipping snackbar');
                                        return;
                                      }
                                      if (revenueCat.errorMessage != null) {
                                        debugPrint('❌ [PackagesScreen] Error detected: ${revenueCat.errorMessage}');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(revenueCat.errorMessage!),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                                          ),
                                        );
                                      } else if (info != null) {
                                        debugPrint('✅ [PackagesScreen] Success! Purchases restored');
                                        debugPrint('📦 [PackagesScreen] Active subscriptions: ${info.activeSubscriptions.length}');
                                        debugPrint('🎫 [PackagesScreen] Active entitlements: ${info.entitlements.active.length}');
                                        
                                        // Refresh customer info and offerings to update entire app
                                        await revenueCat.refreshCustomerInfo();
                                        await revenueCat.refreshOfferings();
                                        debugPrint('🔄 [PackagesScreen] Refreshed customer info and offerings globally');
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Purchases restored successfully!'),
                                            backgroundColor: Color(0xFF0d9488),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                                          ),
                                        );
                                      } else {
                                        debugPrint('⚠️ [PackagesScreen] No purchases found or user cancelled');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('No purchases to restore.'),
                                            backgroundColor: Colors.orange,
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                                          ),
                                        );
                                      }
                                    } finally {
                                      debugPrint('🏁 [PackagesScreen] Setting isRestoringPurchases = false (finally block)');
                                      revenueCat.setIsRestoringPurchases(false);
                                      debugPrint('🔄 [PackagesScreen] ========== RESTORE PURCHASES COMPLETED ==========');
                                    }
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.ease,
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: isRestoring
                                    ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade300])
                                    : LinearGradient(colors: [Color(0xFF0d9488), Color(0xFF14b8a6)]),
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
                                  isRestoring
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.restore, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text(
                                    isRestoring ? 'Restoring...' : 'Restore Purchases',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  
                  // Package items
                  if (index > 0 && index <= filteredPackages.length) {
                    final pkg = filteredPackages[index - 1]; // Adjust index for packages
                    final productId = pkg.productId;
                    final isThisPackageSubscribed = revenueCat.isProductSubscribed(productId);
                    
                    debugPrint('📋 [PackagesScreen] Building package card ${index - 1}: ${pkg.name}');
                    debugPrint('   - Product ID: $productId');
                    debugPrint('   - Is this package subscribed: $isThisPackageSubscribed');
                    debugPrint('   - Subscribed product ID: ${revenueCat.subscribedProductId ?? "none"}');
                    
                    return Column(
                      children: [
                        Consumer<PackagesProvider>(
                          builder: (context, packagesProvider, _) => PackageCard(
                            package: pkg,
                            delay: (index - 1) * 100, // Adjust delay
                            hasAccess: isThisPackageSubscribed,
                            onEnroll: isThisPackageSubscribed
                                ? () {
                                    debugPrint('👆 [PackagesScreen] Access button tapped for subscribed package - navigating to dashboard');
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const SubscriberDashboardScreen()),
                                    );
                                  }
                                : () {
                                    debugPrint('👆 [PackagesScreen] Subscribe button tapped for package: ${pkg.name} (index: ${index - 1}, productId: $productId)');
                                    _purchasePackage(context, index - 1, pkg); // Adjust index
                                  },
                            isLoading: revenueCat.isPurchasing && packagesProvider.purchasingIndex == (index - 1), // Adjust index
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  
                  // Last item: Legal links at the bottom (no duplicate restore button)
                  return Column(
                    children: [
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
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );
    } else {
      return ProfileScreen(
        userName: authProvider.userName ?? '',
        userEmail: authProvider.userEmail ?? '',
        userGender: authProvider.userGender,
      );
    }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️  [PackagesScreen] Building main widget tree');
    final authProvider = Provider.of<AuthProvider>(context);
    return ChangeNotifierProvider<PackagesProvider>(
      create: (_) => PackagesProvider(),
      child: Consumer3<PackagesProvider, ThemeProvider, DrawerProvider>(
        builder: (context, provider, themeProvider, drawerProvider, _) {
          final isDarkMode = themeProvider.isDarkMode;
          final isDrawerOpen = drawerProvider.isDrawerOpen;
          debugPrint('🔄 [PackagesScreen] Main Consumer rebuild');
          debugPrint('   - isDarkMode: $isDarkMode');
          debugPrint('   - isDrawerOpen: $isDrawerOpen');
          debugPrint('   - selectedIndex: ${provider.selectedIndex}');

          return Stack(
            children: [
              Scaffold(
                key: _scaffoldKey,
                backgroundColor: isDarkMode ? AppConstants.bgColorDark : AppConstants.bgColor,
                appBar: widget.showAppBar
                    ? PreferredSize(
                        preferredSize: Size.fromHeight(kToolbarHeight),
                        child: AppBarWidget(
                          notificationCount: notificationCount,
                          onMenuTap: () => _toggleDrawer(context),
                          onNotificationTap: () {},
                        ),
                      )
                    : null,
                body: _getScreenContent(context),
              ),
              DrawerMenu(
                closeDrawer: () => _closeDrawer(context),
                toggleDarkMode: () => _toggleDarkMode(context),
                handleNavigation: (route) => _handleNavigation(context, route),
                handleLogout: () => _handleLogout(context),
                onCustomerCenterTap: () {
                  context.read<RevenueCatProvider>().openCustomerCenter();
                },
                userName: authProvider.userName ?? '',
                userEmail: authProvider.userEmail ?? '',
              ),
            ],
          );
        },
      ),
    );
  }
}
