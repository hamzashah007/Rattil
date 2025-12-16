import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/models/package.dart';
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

  List<Package> get filteredPackages {
    return packages;
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
  Future<void> _purchasePackage(BuildContext context, int index, Package uiPackage) async {
    debugPrint('🛒 [PackagesScreen] ========== PURCHASE FLOW STARTED ==========');
    debugPrint('📋 [PackagesScreen] Package details:');
    debugPrint('   - Name: ${uiPackage.name}');
    debugPrint('   - ID: ${uiPackage.id}');
    debugPrint('   - Price: \$${uiPackage.price}');
    debugPrint('   - Index: $index');
    
    final revenueCat = context.read<RevenueCatProvider>();
    
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
    final productId = uiPackage.id.toString().padLeft(2, '0');
    debugPrint('🔎 [PackagesScreen] Matching package to RevenueCat product...');
    debugPrint('   - Looking for product ID: $productId');
    
    final rcPackage = revenueCat.findPackageByStoreProductId(productId);

    if (rcPackage == null) {
      debugPrint('❌ [PackagesScreen] Package NOT FOUND in RevenueCat offerings!');
      debugPrint('   - Searched product ID: $productId');
      debugPrint('   - Available packages: ${revenueCat.availablePackages.length}');
      if (revenueCat.availablePackages.isNotEmpty) {
        debugPrint('   - Available product IDs:');
        for (final pkg in revenueCat.availablePackages) {
          debugPrint('     • ${pkg.storeProduct.identifier} (${pkg.identifier})');
        }
      }
      if (!mounted) {
        debugPrint('⚠️  [PackagesScreen] Widget not mounted, aborting...');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product not available. Please check your connection and try again.'),
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
    
    // Purchase using the package directly (best practice)
    debugPrint('💳 [PackagesScreen] Initiating purchase with RevenueCat...');
    debugPrint('   - Calling purchasePackage()...');
    
    final customerInfo = await revenueCat.purchasePackage(rcPackage);
    
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
        SnackBar(content: Text(revenueCat.errorMessage!)),
      );
      debugPrint('🛑 [PackagesScreen] ========== PURCHASE FLOW FAILED ==========');
    } else if (customerInfo != null) {
      debugPrint('✅ [PackagesScreen] Purchase completed successfully!');
      debugPrint('   - Customer Info received');
      debugPrint('   - Checking entitlement access...');
      
      // Retry mechanism: Wait for subscription status to sync
      // Keep purchasing state active until subscription is confirmed
      bool subscriptionActive = false;
      
      // First, immediately refresh customer info (no delay)
      debugPrint('   - Immediate refresh (attempt 1/3)...');
      await revenueCat.refreshCustomerInfo();
      
      // Check immediately
      final hasAccessImmediate = revenueCat.hasAccess;
      final isThisPackageSubscribedImmediate = revenueCat.isProductSubscribed(productId);
      debugPrint('   - Immediate check: Has access: $hasAccessImmediate, Is subscribed: $isThisPackageSubscribedImmediate');
      
      if (hasAccessImmediate && isThisPackageSubscribedImmediate) {
        subscriptionActive = true;
        debugPrint('   ✅ Subscription status confirmed immediately!');
      } else {
        // If not confirmed, retry with delays
        for (int attempt = 1; attempt < 3; attempt++) {
          debugPrint('   - Retry attempt ${attempt + 1}/3, waiting for sync...');
          await Future.delayed(Duration(milliseconds: 200 * attempt)); // 200ms, 400ms
          
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
                bottom: 100,
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
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 75),
                itemCount: filteredPackages.length,
                itemBuilder: (context, index) {
                  final pkg = filteredPackages[index];
                  final productId = pkg.id.toString().padLeft(2, '0');
                  final isThisPackageSubscribed = revenueCat.isProductSubscribed(productId);
                  
                  debugPrint('📋 [PackagesScreen] Building package card $index: ${pkg.name}');
                  debugPrint('   - Product ID: $productId');
                  debugPrint('   - Is this package subscribed: $isThisPackageSubscribed');
                  debugPrint('   - Subscribed product ID: ${revenueCat.subscribedProductId ?? "none"}');
                  
                  return Consumer<PackagesProvider>(
                    builder: (context, packagesProvider, _) => PackageCard(
                      package: pkg,
                      delay: index * 100,
                      hasAccess: isThisPackageSubscribed,
                      onEnroll: isThisPackageSubscribed
                          ? () {
                              debugPrint('👆 [PackagesScreen] Access button tapped for subscribed package - navigating to dashboard');
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SubscriberDashboardScreen()),
                              );
                            }
                          : () {
                              debugPrint('👆 [PackagesScreen] Subscribe button tapped for package: ${pkg.name} (index: $index, productId: $productId)');
                              _purchasePackage(context, index, pkg);
                            },
                      isLoading: revenueCat.isPurchasing && packagesProvider.purchasingIndex == index,
                    ),
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
              if (!isDrawerOpen)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CurvedBottomBar(
                    selectedIndex: provider.selectedIndex,
                    onTap: (index) => _onBottomBarTap(context, index),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
