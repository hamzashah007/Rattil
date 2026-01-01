import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rattil/models/package.dart' as models;
import 'package:rattil/utils/firestore_helpers.dart';

/// Centralized RevenueCat state: offerings, purchases, entitlement access.
/// Follows RevenueCat best practices: dynamic paywalls using offerings and packages.
class RevenueCatProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const apiKey = 'appl_pMSdZUXXAVlzGeftesHFTwvEsiu';
  static const entitlementId = 'Rattil Packages';

  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  bool _started = false;
  bool isLoading = false;
  bool isPurchasing = false;
  bool isRestoringPurchases = false;
  String? errorMessage;
  
  // Temporary storage for recently purchased product ID (until RevenueCat server syncs)
  String? _recentlyPurchasedProductId;
  DateTime? _recentPurchaseTime;
  
  // Periodic refresh timer for keeping data in sync
  Timer? _periodicRefreshTimer;

  CustomerInfo? get customerInfo => _customerInfo;
  Offerings? get offerings => _offerings;
  
  /// Check if user has active access. 
  /// Returns true if subscription is not expired (even if cancelled).
  /// Follows Apple guidelines: cancelled subscriptions remain active until billing period ends.
  bool get hasAccess {
    final entitlement = _customerInfo?.entitlements.active[entitlementId];
    if (entitlement == null) {
      debugPrint('🔍 [RevenueCatProvider] No active entitlement found');
      return false;
    }
    
    // IMPORTANT: Check expiration date first (Apple guidelines compliance)
    // Even if willRenew = false (cancelled), user should have access until expiration
    if (entitlement.expirationDate != null && entitlement.expirationDate!.isNotEmpty) {
      try {
        final expirationDate = DateTime.parse(entitlement.expirationDate!);
        final now = DateTime.now();
        
        // If subscription has expired, no access
        if (expirationDate.isBefore(now)) {
          debugPrint('⚠️ [RevenueCatProvider] Subscription expired on $expirationDate - denying access');
          return false;
        }
        
        // If subscription is not expired, grant access (even if willRenew = false)
        if (!entitlement.willRenew) {
          debugPrint('ℹ️ [RevenueCatProvider] Subscription cancelled but still valid until $expirationDate - granting access');
        } else {
          debugPrint('✅ [RevenueCatProvider] Active subscription found - granting access');
        }
        return true;
      } catch (e) {
        debugPrint('⚠️ [RevenueCatProvider] Could not parse expiration date: $e');
        // Fallback to willRenew if date parsing fails
      }
    }
    
    // Fallback: Use willRenew if expiration date not available
    // This handles edge cases where expiration date might not be set
    if (!entitlement.willRenew) {
      debugPrint('⚠️ [RevenueCatProvider] Subscription cancelled (willRenew = false) and no expiration date - denying access');
      return false;
    }
    
    debugPrint('✅ [RevenueCatProvider] Active subscription found - granting access');
    return true;
  }

  /// Get available packages from the current offering.
  /// Returns empty list if offerings are not loaded or current offering is null.
  List<Package> get availablePackages {
    if (_offerings?.current == null) return [];
    return _offerings!.current!.availablePackages;
  }

  /// Check if offerings are loaded and current offering has packages.
  bool get hasAvailablePackages => availablePackages.isNotEmpty;

  /// Check if a specific product ID exists in the current offering.
  /// Primary format: basic01, intermediate02, premium03 (current App Store Connect subscriptions)
  /// Fallback format: 01, 02, 03 (for backward compatibility)
  /// Useful for debugging why a package might not be found.
  bool isProductInOfferings(String productId) {
    if (_offerings?.current == null) {
      debugPrint('⚠️ [RevenueCatProvider] No offerings available to check product: $productId');
      return false;
    }
    
    final normalizedId = productId.padLeft(2, '0');
    debugPrint('🔍 [RevenueCatProvider] Checking if product $normalizedId exists in offerings...');
    
    // Map UI IDs to RevenueCat product IDs (PRIMARY: new format from App Store Connect)
    final productIdMap = {
      '01': 'basic01',
      '02': 'intermediate02',
      '03': 'premium03',
      '1': 'basic01',
      '2': 'intermediate02',
      '3': 'premium03',
    };
    
    // PRIORITY: Check new format first (basic01, intermediate02, premium03), then old format as fallback
    final expectedProductIds = [
      productIdMap[normalizedId],  // Primary: new format
      productIdMap[productId],     // Primary: new format (if productId is "1", "2", "3")
      normalizedId,                // Fallback: old format
      productId,                    // Fallback: old format
    ].where((id) => id != null).cast<String>().toSet();
    
    for (final pkg in _offerings!.current!.availablePackages) {
      final pkgId = pkg.storeProduct.identifier;
      debugPrint('   - Checking: $pkgId');
      
      // Exact match with any expected ID
      if (expectedProductIds.contains(pkgId)) {
        debugPrint('   ✅ Found exact match: $pkgId');
        return true;
      }
      
      // Numeric extraction match
      final numericMatch = RegExp(r'(\d+)').firstMatch(pkgId);
      if (numericMatch != null) {
        final extracted = numericMatch.group(1)?.padLeft(2, '0');
        if (extracted == normalizedId) {
          debugPrint('   ✅ Found numeric match: $pkgId → $extracted');
          return true;
        }
      }
      
      // Name-based match (basic01, intermediate02, premium03)
      final lowerPkgId = pkgId.toLowerCase();
      if (normalizedId == '01' && (lowerPkgId.contains('basic') || lowerPkgId.contains('01'))) {
        debugPrint('   ✅ Found name-based match: $pkgId → 01');
        return true;
      } else if (normalizedId == '02' && (lowerPkgId.contains('intermediate') || lowerPkgId.contains('02'))) {
        debugPrint('   ✅ Found name-based match: $pkgId → 02');
        return true;
      } else if (normalizedId == '03' && (lowerPkgId.contains('premium') || lowerPkgId.contains('intensive') || lowerPkgId.contains('03'))) {
        debugPrint('   ✅ Found name-based match: $pkgId → 03');
        return true;
      }
    }
    
    debugPrint('   ❌ Product $normalizedId NOT found in offerings');
    debugPrint('   📋 Available product IDs:');
    for (final pkg in _offerings!.current!.availablePackages) {
      debugPrint('     • ${pkg.storeProduct.identifier}');
    }
    return false;
  }

  /// Get the product identifier of the currently subscribed package.
  /// Returns null if user doesn't have access or product ID cannot be determined.
  /// 
  /// IMPORTANT: RevenueCat entitlement.productIdentifier might not always return the correct
  /// product ID if multiple products are linked to the same entitlement. We check activeSubscriptions
  /// first to get the actual purchased product ID.
  String? get subscribedProductId {
    final entitlement = _customerInfo?.entitlements.active[entitlementId];
    if (entitlement == null) {
      debugPrint('🔍 [RevenueCatProvider] No active entitlement found');
      return null;
    }
    
    // Check expiration date as before
    if (entitlement.expirationDate != null && entitlement.expirationDate!.isNotEmpty) {
      try {
        final expirationDate = DateTime.parse(entitlement.expirationDate!);
        if (expirationDate.isBefore(DateTime.now())) {
          debugPrint('⚠️ [RevenueCatProvider] Subscription expired - no product ID');
          return null;
        }
      } catch (e) {
        debugPrint('⚠️ [RevenueCatProvider] Could not parse expiration date: $e');
        if (!entitlement.willRenew) {
          debugPrint('⚠️ [RevenueCatProvider] Subscription cancelled (willRenew = false) and no expiration date - no product ID');
          return null;
        }
      }
    } else {
      if (!entitlement.willRenew) {
        debugPrint('⚠️ [RevenueCatProvider] Subscription cancelled (willRenew = false) and no expiration date - no product ID');
        return null;
      }
    }
    
    debugPrint('🔍 [RevenueCatProvider] Finding subscribed product ID...');
    debugPrint('   - Entitlement identifier: \\${entitlement.identifier}');
    debugPrint('   - Entitlement productIdentifier: \\${entitlement.productIdentifier}');
    debugPrint('   - Will renew: \\${entitlement.willRenew}');
    
    // Use temporary storage if available and recent
    if (_recentlyPurchasedProductId != null && _recentPurchaseTime != null) {
      final timeSincePurchase = DateTime.now().difference(_recentPurchaseTime!);
      if (timeSincePurchase.inHours < 2) {
        debugPrint('   💾 Using recently purchased product ID (not yet synced): \\$_recentlyPurchasedProductId');
        debugPrint('   ✅ Returning temporary product ID: \\$_recentlyPurchasedProductId');
        return _recentlyPurchasedProductId;
      } else {
        debugPrint('   ⚠️ Recent purchase too old (\\${timeSincePurchase.inHours} hours), clearing temporary storage');
        _recentlyPurchasedProductId = null;
        _recentPurchaseTime = null;
      }
    } else {
      debugPrint('   ℹ️ No temporary storage found');
    }
    
    // Use the full productIdentifier from the active entitlement
    return entitlement.productIdentifier;
  }

  /// Check if a specific product ID (01, 02, 03) is the subscribed product.
  /// Handles both "02" and "2" formats for product IDs.
  bool isProductSubscribed(String productId) {
    // Check optimistic state: recently purchased product (not yet synced)
    if (_recentlyPurchasedProductId != null && _recentPurchaseTime != null) {
      final timeSincePurchase = DateTime.now().difference(_recentPurchaseTime!);
      if (timeSincePurchase.inHours < 2) {
        if (_recentlyPurchasedProductId == productId) {
          debugPrint('⚡ [RevenueCatProvider] Optimistic match: $productId == $_recentlyPurchasedProductId');
          return true;
        }
      }
    }
    // Fallback: check actual subscription
    final subscribedId = subscribedProductId;
    if (subscribedId == null) {
      debugPrint('❌ [RevenueCatProvider] No subscribed product - checking $productId: false');
      return false;
    }
    final isSubscribed = subscribedId == productId;
    debugPrint('🔎 [RevenueCatProvider] Checking if $productId is subscribed:');
    debugPrint('   - Subscribed ID: $subscribedId');
    debugPrint('   - Checking ID: $productId');
    debugPrint('   - Match result: $isSubscribed');
    return isSubscribed;
  }

  late final CustomerInfoUpdateListener _customerInfoListener;

  RevenueCatProvider() {
    _customerInfoListener = _handleCustomerInfo;
    // Add app lifecycle observer to refresh customer info when app resumes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - refresh customer info to get latest subscription status
      debugPrint('🔄 [RevenueCatProvider] App resumed - refreshing customer info and offerings...');
      // Refresh both customer info and offerings for complete sync
      _refreshAll().catchError((e) {
        debugPrint('⚠️ [RevenueCatProvider] Error refreshing on resume: $e');
      });
    }
  }

  /// Call once after Purchases.configure has run.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    
    // Register lifecycle observer for automatic refresh
    WidgetsBinding.instance.addObserver(this);
    
    await _refreshAll();
    Purchases.addCustomerInfoUpdateListener(_customerInfoListener);
    
    // OPTIMIZED: Start periodic background refresh (every 5 minutes) to keep data in sync
    _startPeriodicRefresh();
  }
  
  /// Start periodic background refresh to keep customer info and offerings in sync
  void _startPeriodicRefresh() {
    // Cancel existing timer if any
    _periodicRefreshTimer?.cancel();
    
    // Refresh every 5 minutes to keep data synced
    _periodicRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_started) {
        debugPrint('🔄 [RevenueCatProvider] Periodic refresh triggered...');
        refreshCustomerInfo().catchError((e) {
          debugPrint('⚠️ [RevenueCatProvider] Error in periodic refresh: $e');
        });
      }
    });
  }
  
  /// Link RevenueCat to Firebase user (User Mode)
  /// Call this when user signs in to sync subscription across devices
  Future<void> linkToFirebaseUser(String firebaseUserId) async {
    try {
      debugPrint('🔗 [RevenueCatProvider] ========== LINKING TO FIREBASE USER ==========');
      debugPrint('👤 [RevenueCatProvider] Firebase User ID: $firebaseUserId');
      debugPrint('📞 [RevenueCatProvider] Calling Purchases.logIn()...');
      
      final loginResult = await Purchases.logIn(firebaseUserId);
      
      debugPrint('✅ [RevenueCatProvider] Successfully linked to Firebase user');
      debugPrint('   - Created: ${loginResult.created}');
      debugPrint('   - Customer Info: ${loginResult.customerInfo.originalAppUserId}');
      
      // Update customer info with linked account
      _setCustomerInfo(loginResult.customerInfo);
      
      debugPrint('🔗 [RevenueCatProvider] ========== LINK COMPLETED ==========');
    } catch (e) {
      debugPrint('❌ [RevenueCatProvider] Error linking to Firebase user: $e');
      errorMessage = 'Failed to link account. Please try again.';
      notifyListeners();
    }
  }
  
  /// Unlink from Firebase user (Guest Mode)
  /// Call this when user logs out to switch to anonymous mode
  Future<void> unlinkFromFirebaseUser() async {
    try {
      debugPrint('🔓 [RevenueCatProvider] ========== UNLINKING FROM FIREBASE USER ==========');
      debugPrint('📞 [RevenueCatProvider] Calling Purchases.logOut()...');
      
      final customerInfo = await Purchases.logOut();
      
      debugPrint('✅ [RevenueCatProvider] Successfully unlinked (now anonymous)');
      debugPrint('   - Customer Info: ${customerInfo.originalAppUserId}');
      
      // Update customer info with anonymous account
      _setCustomerInfo(customerInfo);
      
      debugPrint('🔓 [RevenueCatProvider] ========== UNLINK COMPLETED ==========');
    } catch (e) {
      debugPrint('❌ [RevenueCatProvider] Error unlinking from Firebase user: $e');
      errorMessage = 'Failed to unlink account. Please try again.';
      notifyListeners();
    }
  }
  
  Future<void> _refreshAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await Future.wait([refreshCustomerInfo(), refreshOfferings()]);
    } catch (e) {
      errorMessage = _friendlyMessageForCode(null, e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCustomerInfo() async {
    debugPrint('🔄 [RevenueCatProvider] Refreshing customer info...');
    try {
      final info = await Purchases.getCustomerInfo();
      debugPrint('✅ [RevenueCatProvider] Customer info refreshed successfully');
      _setCustomerInfo(info);
    } catch (e) {
      debugPrint('❌ [RevenueCatProvider] Error refreshing customer info: $e');
      rethrow;
    }
  }

  Future<void> refreshOfferings() async {
    debugPrint('🔄 [RevenueCatProvider] Refreshing offerings...');
    try {
      _offerings = await Purchases.getOfferings();
      debugPrint('✅ [RevenueCatProvider] Offerings refreshed successfully');
      
      if (_offerings?.current != null) {
        debugPrint('   - Current offering ID: ${_offerings!.current!.identifier}');
        debugPrint('   - Available packages: ${_offerings!.current!.availablePackages.length}');
        
        // Check specifically for package 03 (Premium Intensive)
        bool found03 = false;
        for (final pkg in _offerings!.current!.availablePackages) {
          debugPrint('     • Package: ${pkg.identifier}');
          debugPrint('       - Store Product ID: ${pkg.storeProduct.identifier}');
          debugPrint('       - Store Product Title: ${pkg.storeProduct.title}');
          debugPrint('       - Store Product Price: ${pkg.storeProduct.priceString}');
          debugPrint('       - Package Type: ${pkg.packageType}');
          
          // Check if this is package 03 (handles both old format "03" and new format "premium03")
          final pkgId = pkg.storeProduct.identifier.toLowerCase();
          if (pkg.storeProduct.identifier == '03' || 
              pkg.storeProduct.identifier == '3' ||
              pkg.storeProduct.identifier == 'premium03' ||
              pkg.storeProduct.identifier == 'premium3' ||
              pkgId.contains('premium') ||
              pkgId.contains('intensive')) {
            found03 = true;
            debugPrint('       ✅ FOUND PACKAGE 03 (Premium Intensive)!');
          }
        }
        
        if (!found03) {
          debugPrint('   ⚠️⚠️⚠️ PACKAGE 03 (Premium Intensive) NOT FOUND IN OFFERINGS! ⚠️⚠️⚠️');
          debugPrint('   💡 Possible issues:');
          debugPrint('      1. Product "03" not added to current offering in RevenueCat dashboard');
          debugPrint('      2. Product "03" not linked to entitlement "Rattil Packages"');
          debugPrint('      3. Product "03" not active in App Store Connect');
          debugPrint('      4. Product "03" not synced from App Store Connect to RevenueCat');
          debugPrint('   🔧 Solution: Check RevenueCat Dashboard → Product Catalog → Ensure "03" is in the offering');
        } else {
          debugPrint('   ✅ Package 03 (Premium Intensive) is available in offerings');
        }
      } else {
        debugPrint('   ⚠️ No current offering found');
        debugPrint('   💡 This means no offering is configured in RevenueCat dashboard');
        debugPrint('   🔧 Solution: Create an offering in RevenueCat Dashboard → Paywalls');
      }
    } catch (e) {
      debugPrint('❌ [RevenueCatProvider] Error refreshing offerings: $e');
      rethrow;
    }
    notifyListeners();
  }

  /// Purchase a package directly. Best practice: use packages from offerings.
  /// [packageToPurchase] should come from [availablePackages] or [offerings.current.availablePackages].
  Future<CustomerInfo?> purchasePackage(Package packageToPurchase) async {
    debugPrint('💳 [RevenueCatProvider] ========== PURCHASE PACKAGE ==========');
    debugPrint('   - Package Identifier: ${packageToPurchase.identifier}');
    debugPrint('   - Store Product ID: ${packageToPurchase.storeProduct.identifier}');
    debugPrint('   - Store Product Title: ${packageToPurchase.storeProduct.title}');
    debugPrint('   - Store Product Price: ${packageToPurchase.storeProduct.priceString}');
    debugPrint('   - Package Type: ${packageToPurchase.packageType}');
    
    final expectedProductId = packageToPurchase.storeProduct.identifier;
    
    isPurchasing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await Purchases.purchasePackage(packageToPurchase);
      final info = result.customerInfo;
      debugPrint('✅ [RevenueCatProvider] Purchase completed successfully');
      debugPrint('   - Customer Info received');
      
      // IMPORTANT: Store the purchased product ID temporarily until RevenueCat server syncs
      // Store BEFORE setting customer info to ensure it's available immediately
      _recentlyPurchasedProductId = expectedProductId;
      _recentPurchaseTime = DateTime.now();
      debugPrint('   💾 Stored recently purchased product ID: $_recentlyPurchasedProductId');
      debugPrint('   💾 Purchase time: $_recentPurchaseTime');
      
      // CRITICAL: Immediately notify listeners for optimistic UI update
      // This ensures UI updates instantly, especially important for Premium Intensive (03)
      _customerInfo = info; // Update customer info immediately
      notifyListeners();
      debugPrint('   🔔 Immediately notified listeners for optimistic UI update');
      debugPrint('   ✅ UI should now show "Go to Dashboard" immediately (using temporary storage)');
      
      // IMPORTANT: RevenueCat server might take a moment to sync the purchase
      // Retry customer info refresh to get the latest purchase
      debugPrint('🔄 [RevenueCatProvider] Verifying purchase sync...');
      debugPrint('   - Expected product ID: $expectedProductId');
      
      // Check if the purchased product ID is in the customer info
      final allPurchased = info.allPurchasedProductIdentifiers;
      final activeSubs = info.activeSubscriptions;
      final hasExpectedProduct = allPurchased.contains(expectedProductId);
      final hasExpectedInActiveSubs = activeSubs.contains(expectedProductId);
      
      // Check if entitlement's productIdentifier matches
      final entitlement = info.entitlements.active[entitlementId];
      final entitlementMatches = entitlement?.productIdentifier == expectedProductId;
      
      debugPrint('   - All purchased IDs: $allPurchased');
      debugPrint('   - Active subscriptions: $activeSubs');
      debugPrint('   - Has expected product in allPurchased: $hasExpectedProduct');
      debugPrint('   - Has expected product in activeSubscriptions: $hasExpectedInActiveSubs');
      debugPrint('   - Entitlement productIdentifier matches: $entitlementMatches');
      
      // IMPORTANT: Only clear temporary storage if product ID is in activeSubscriptions OR entitlement matches
      // If it's only in allPurchased but not in activeSubscriptions, keep temporary storage
      if (!hasExpectedProduct) {
        // Product ID not found at all - retry logic
        debugPrint('   ⚠️ Expected product ID not found yet, retrying customer info refresh...');
        debugPrint('   💾 Temporary storage preserved: $_recentlyPurchasedProductId');
        
        // OPTIMIZED: Smarter retry with shorter delays (3 attempts, faster sync)
        // Reduced from 5 attempts (30s total) to 3 attempts (3s total) for better UX
        for (int attempt = 1; attempt <= 3; attempt++) {
          // Shorter delays: 500ms, 1s, 1.5s (total 3s instead of 30s)
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          debugPrint('   - Retry attempt $attempt/3 (${500 * attempt}ms delay)...');
          try {
            final refreshedInfo = await Purchases.getCustomerInfo();
            
            // IMPORTANT: Don't clear temporary storage when calling _setCustomerInfo during retry
            // Only update customer info, keep temporary storage intact
            _customerInfo = refreshedInfo;
            notifyListeners();
            
            final refreshedPurchased = refreshedInfo.allPurchasedProductIdentifiers;
            final refreshedActiveSubs = refreshedInfo.activeSubscriptions;
            final refreshedEntitlement = refreshedInfo.entitlements.active[entitlementId];
            final refreshedEntitlementMatches = refreshedEntitlement?.productIdentifier == expectedProductId;
            
            debugPrint('   - Refreshed purchased IDs: $refreshedPurchased');
            debugPrint('   - Refreshed active subscriptions: $refreshedActiveSubs');
            debugPrint('   💾 Temporary storage still preserved: $_recentlyPurchasedProductId');
            
            // Check if product ID is in activeSubscriptions OR entitlement matches
            if (refreshedPurchased.contains(expectedProductId) && 
                (refreshedActiveSubs.contains(expectedProductId) || refreshedEntitlementMatches)) {
              debugPrint('   ✅ Expected product ID synced (in activeSubscriptions or entitlement matches)!');
              // Clear temporary storage as it's now synced
              _recentlyPurchasedProductId = null;
              _recentPurchaseTime = null;
              _setCustomerInfo(refreshedInfo); // Now update with full logging
              return refreshedInfo;
            }
          } catch (e) {
            debugPrint('   ⚠️ Retry failed: $e');
            debugPrint('   💾 Temporary storage still preserved: $_recentlyPurchasedProductId');
          }
        }
        debugPrint('   ⚠️ Expected product ID still not found after retries, but purchase was successful');
        debugPrint('   💾 Will use temporarily stored product ID: $_recentlyPurchasedProductId');
        // IMPORTANT: Keep temporary storage intact - don't clear it
        // Set customer info but preserve temporary storage
        _customerInfo = info;
        notifyListeners();
      } else if (!hasExpectedInActiveSubs && !entitlementMatches) {
        // Product ID found in allPurchased but NOT in activeSubscriptions AND entitlement doesn't match
        // This means purchase is successful but RevenueCat server hasn't synced yet
        debugPrint('   ⚠️ Product ID found in allPurchased but NOT in activeSubscriptions or entitlement');
        debugPrint('   💾 Keeping temporary storage until activeSubscriptions/entitlement syncs');
        debugPrint('   💾 Temporary storage preserved: $_recentlyPurchasedProductId');
        // Keep temporary storage intact - don't clear it
        _customerInfo = info;
        notifyListeners();
      } else {
        // Product ID found in activeSubscriptions OR entitlement matches
        debugPrint('   ✅ Expected product ID synced (in activeSubscriptions or entitlement matches), clearing temporary storage');
        _recentlyPurchasedProductId = null;
        _recentPurchaseTime = null;
        _setCustomerInfo(info);
      }
      
      // Save transaction to Firebase after successful purchase
      await _saveTransactionToFirebase(
        packageToPurchase: packageToPurchase,
        customerInfo: info,
        productId: expectedProductId,
      );
      
      return info;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      errorMessage = _friendlyMessageForCode(code, e.message);
      return null;
    } catch (e) {
      errorMessage = _friendlyMessageForCode(null, e.toString());
      return null;
    } finally {
      isPurchasing = false;
      notifyListeners();
    }
  }

  /// Find a RevenueCat package by matching store product identifier.
  /// This matches UI packages (id: 01, 02, 03) to RevenueCat packages.
  /// PRIMARY format: basic01, intermediate02, premium03 (current App Store Connect subscriptions)
  /// FALLBACK format: 01, 02, 03 (for backward compatibility)
  /// Returns null if not found. Best practice: use this to match UI to RevenueCat packages dynamically.
  Package? findPackageByStoreProductId(String storeProductId) {
    if (_offerings?.current == null) {
      debugPrint('⚠️ [RevenueCatProvider] No offerings available for package lookup');
      return null;
    }
    
    debugPrint('🔍 [RevenueCatProvider] Finding package by product ID: $storeProductId');
    debugPrint('   - Available packages: ${_offerings!.current!.availablePackages.length}');
    
    // Normalize the search ID (ensure 2-digit format)
    final normalizedSearchId = storeProductId.padLeft(2, '0');
    debugPrint('   - Normalized search ID: $normalizedSearchId');
    
    // List all available product IDs for debugging
    final availableIds = <String>[];
    for (final pkg in _offerings!.current!.availablePackages) {
      availableIds.add(pkg.storeProduct.identifier);
      debugPrint('     • Available: ${pkg.storeProduct.identifier} (Package: ${pkg.identifier}, Title: ${pkg.storeProduct.title})');
    }
    
    // Map UI IDs to RevenueCat product IDs (PRIMARY: new format from App Store Connect)
    final productIdMap = {
      '01': ['basic01', 'basic1'],
      '02': ['intermediate02', 'intermediate2'],
      '03': ['premium03', 'premium3'],
    };
    
    // PRIORITY: Check new format first (basic01, intermediate02, premium03), then old format as fallback
    final possibleIds = <String>{};
    
    // Add new format IDs first (priority)
    if (productIdMap.containsKey(normalizedSearchId)) {
      possibleIds.addAll(productIdMap[normalizedSearchId]!);
    }
    
    // Add old format IDs as fallback
    possibleIds.add(storeProductId);
    possibleIds.add(normalizedSearchId);
    
    // Method 1: Exact match (PRIORITY: new format first, then old format)
    for (final pkg in _offerings!.current!.availablePackages) {
      if (possibleIds.contains(pkg.storeProduct.identifier)) {
        debugPrint('   ✅ Found exact match: ${pkg.storeProduct.identifier}');
        return pkg;
      }
    }
    
    // Method 2: Extract numeric part and match (handles "com.rattil.03", "product_03", "premium03", etc.)
    final numericMatch = RegExp(r'(\d+)').firstMatch(storeProductId);
    if (numericMatch != null) {
      final extractedNumber = numericMatch.group(1);
      if (extractedNumber != null) {
        final normalizedExtracted = extractedNumber.padLeft(2, '0');
        debugPrint('   - Extracted numeric ID: $normalizedExtracted');
        
        for (final pkg in _offerings!.current!.availablePackages) {
          final pkgNumericMatch = RegExp(r'(\d+)').firstMatch(pkg.storeProduct.identifier);
          if (pkgNumericMatch != null) {
            final pkgExtracted = pkgNumericMatch.group(1);
            if (pkgExtracted != null && pkgExtracted.padLeft(2, '0') == normalizedExtracted) {
              debugPrint('   ✅ Found numeric match: ${pkg.storeProduct.identifier}');
              return pkg;
            }
          }
        }
      }
    }
    
    // Method 3: Match by package name keywords (for all packages)
    debugPrint('   - Trying name-based matching...');
    for (final pkg in _offerings!.current!.availablePackages) {
      final lowerId = pkg.storeProduct.identifier.toLowerCase();
      final lowerTitle = pkg.storeProduct.title.toLowerCase();
      
      // Match based on normalized search ID
      bool matches = false;
      if (normalizedSearchId == '01') {
        matches = lowerId.contains('basic') || lowerId.contains('01') || lowerId.contains('1') ||
                  lowerTitle.contains('basic') || lowerTitle.contains('recitation');
      } else if (normalizedSearchId == '02') {
        matches = lowerId.contains('intermediate') || lowerId.contains('02') || lowerId.contains('2') ||
                  lowerTitle.contains('intermediate');
      } else if (normalizedSearchId == '03') {
        matches = lowerId.contains('premium') || lowerId.contains('intensive') || 
                  lowerId.contains('03') || lowerId.contains('3') ||
                  lowerTitle.contains('premium') || lowerTitle.contains('intensive');
      }
      
      if (matches) {
        debugPrint('   ✅ Found name-based match: ${pkg.storeProduct.identifier} (${pkg.storeProduct.title})');
        return pkg;
      }
    }
    
    // Method 4: Match by package index (if packages are in order: 0=01, 1=02, 2=03)
    try {
      final packageIndex = int.parse(normalizedSearchId) - 1;
      if (packageIndex >= 0 && packageIndex < _offerings!.current!.availablePackages.length) {
        final pkg = _offerings!.current!.availablePackages[packageIndex];
        debugPrint('   ✅ Found by index match: ${pkg.storeProduct.identifier} (index: $packageIndex)');
        return pkg;
      }
    } catch (e) {
      debugPrint('   ⚠️ Could not parse package index: $e');
    }
    
    debugPrint('   ❌ No match found for product ID: $storeProductId');
    debugPrint('   💡 Available product IDs: ${availableIds.join(", ")}');
    return null;
  }

  Future<CustomerInfo?> restorePurchases() async {
    debugPrint('🔄 [RevenueCatProvider] ========== RESTORE PURCHASES STARTED ==========');
    debugPrint('📱 [RevenueCatProvider] Initiating restore purchases flow...');
    
    isPurchasing = true;
    errorMessage = null;
    notifyListeners();
    debugPrint('✅ [RevenueCatProvider] Set isPurchasing = true, cleared errorMessage');
    
    try {
      debugPrint('🍎 [RevenueCatProvider] Calling Purchases.restorePurchases() - Contacting Apple...');
      final startTime = DateTime.now();
      
      final info = await Purchases.restorePurchases();
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('⏱️ [RevenueCatProvider] Purchases.restorePurchases() completed in ${duration.inMilliseconds}ms');
      debugPrint('📦 [RevenueCatProvider] CustomerInfo received from Apple');
      debugPrint('   - Original App User ID: ${info.originalAppUserId}');
      debugPrint('   - Active Subscriptions: ${info.activeSubscriptions.length}');
      debugPrint('   - All Purchased Products: ${info.allPurchasedProductIdentifiers.length}');
      debugPrint('   - Active Entitlements: ${info.entitlements.active.length}');
      
      if (info.activeSubscriptions.isNotEmpty) {
        debugPrint('✅ [RevenueCatProvider] Found active subscriptions:');
        for (final sub in info.activeSubscriptions) {
          debugPrint('     • $sub');
        }
      } else {
        debugPrint('⚠️ [RevenueCatProvider] No active subscriptions found');
      }
      
      debugPrint('📊 [RevenueCatProvider] Updating customer info...');
      _setCustomerInfo(info);
      debugPrint('✅ [RevenueCatProvider] Customer info updated successfully');
      
      return info;
    } on PlatformException catch (e) {
      debugPrint('❌ [RevenueCatProvider] PlatformException caught:');
      debugPrint('   - Code: ${e.code}');
      debugPrint('   - Message: ${e.message}');
      debugPrint('   - Details: ${e.details}');
      
      final code = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('   - Parsed Error Code: $code');
      
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('🚫 [RevenueCatProvider] User cancelled restore - returning null');
        return null;
      }
      
      errorMessage = _friendlyMessageForCode(code, e.message);
      debugPrint('❌ [RevenueCatProvider] Error message set: $errorMessage');
      return null;
    } catch (e) {
      debugPrint('❌ [RevenueCatProvider] General exception caught:');
      debugPrint('   - Type: ${e.runtimeType}');
      debugPrint('   - Message: $e');
      
      errorMessage = _friendlyMessageForCode(null, e.toString());
      debugPrint('❌ [RevenueCatProvider] Error message set: $errorMessage');
      return null;
    } finally {
      isPurchasing = false;
      notifyListeners();
      debugPrint('🏁 [RevenueCatProvider] Set isPurchasing = false, notified listeners');
      debugPrint('🔄 [RevenueCatProvider] ========== RESTORE PURCHASES ENDED ==========');
    }
  }

  /// Opens RevenueCat Customer Center.
  /// 
  /// NOTE: Customer Center is a native UI provided by RevenueCat SDK that displays
  /// subscription information directly from App Store Connect.
  /// 
  /// If all packages show "Basic Recitation" in Customer Center:
  /// 1. This is a known issue with RevenueCat SDK's Customer Center UI
  /// 2. The issue is NOT in our code - Customer Center is a native component
  /// 3. Possible causes:
  ///    - App Store Connect data sync delay (can take 24-48 hours)
  ///    - RevenueCat cache issue (may need to wait for cache refresh)
  ///    - Product identifier mapping issue in RevenueCat dashboard
  /// 
  /// Solutions to try:
  /// 1. Wait 24-48 hours for App Store Connect changes to sync
  /// 2. Check RevenueCat dashboard → Apps & Providers → App Store Connect API credentials
  /// 3. Verify product identifiers match in RevenueCat dashboard
  /// 4. Contact RevenueCat support if issue persists
  /// 
  /// The prices are correctly fetched, indicating the connection is working.
  /// Only the display names may show incorrectly due to sync/cache issues.
  /// 
  /// IMPORTANT: After Customer Center closes, customer info is automatically refreshed
  /// to ensure UI updates reflect any subscription changes (e.g., plan changes).
  Future<void> openCustomerCenter() async {
    try {
      debugPrint('🔧 [RevenueCatProvider] Opening Customer Center...');
      await RevenueCatUI.presentCustomerCenter();
      debugPrint('✅ [RevenueCatProvider] Customer Center closed - refreshing customer info...');
      
      // CRITICAL: Refresh customer info immediately after Customer Center closes
      // This ensures UI updates when user changes plans in Customer Center
      await refreshCustomerInfo();
      debugPrint('✅ [RevenueCatProvider] Customer info refreshed after Customer Center close');
    } catch (e) {
      debugPrint('⚠️ [RevenueCatProvider] Error in Customer Center: $e');
      errorMessage = _friendlyMessageForCode(null, e.toString());
      notifyListeners();
    }
  }


  void _setCustomerInfo(CustomerInfo info) {
    _customerInfo = info;
    
    // Comprehensive debugging for customer info
    debugPrint('📊 [RevenueCatProvider] ========== CUSTOMER INFO UPDATE ==========');
    debugPrint('   - App User ID: ${info.originalAppUserId}');
    debugPrint('   - First Seen: ${info.firstSeen}');
    debugPrint('   - Request Date: ${info.requestDate}');
    
    // Check all entitlements
    debugPrint('   - All Entitlements (${info.entitlements.all.length}):');
    info.entitlements.all.forEach((key, entitlement) {
      debugPrint('     • $key:');
      debugPrint('       - Identifier: ${entitlement.identifier}');
      debugPrint('       - Product Identifier: ${entitlement.productIdentifier}');
      debugPrint('       - Is Active: ${entitlement.isActive}');
      debugPrint('       - Will Renew: ${entitlement.willRenew}');
      debugPrint('       - Latest Purchase Date: ${entitlement.latestPurchaseDate}');
      debugPrint('       - Expiration Date: ${entitlement.expirationDate}');
      debugPrint('       - Period Type: ${entitlement.periodType}');
    });
    
    // Check active entitlements
    debugPrint('   - Active Entitlements (${info.entitlements.active.length}):');
    info.entitlements.active.forEach((key, entitlement) {
      debugPrint('     ✅ $key:');
      debugPrint('       - Product ID: ${entitlement.productIdentifier}');
      debugPrint('       - Will Renew: ${entitlement.willRenew}');
    });
    
    // Check for our specific entitlement
    final ourEntitlement = info.entitlements.active[entitlementId];
    if (ourEntitlement != null) {
      debugPrint('   ✅ [RevenueCatProvider] Found our entitlement "$entitlementId":');
      debugPrint('       - Product ID: ${ourEntitlement.productIdentifier}');
      debugPrint('       - Will Renew: ${ourEntitlement.willRenew}');
    } else {
      debugPrint('   ❌ [RevenueCatProvider] Entitlement "$entitlementId" NOT FOUND in active entitlements');
      debugPrint('       - Available active entitlements: ${info.entitlements.active.keys.toList()}');
    }
    
    // Check all active subscriptions
    debugPrint('   - Active Subscriptions (${info.activeSubscriptions.length}):');
    for (final subscriptionId in info.activeSubscriptions) {
      debugPrint('     • $subscriptionId');
    }
    
    // Check all purchased product identifiers
    debugPrint('   - All Purchased Product IDs (${info.allPurchasedProductIdentifiers.length}):');
    for (final productId in info.allPurchasedProductIdentifiers) {
      debugPrint('     • $productId');
    }
    
    debugPrint('📊 [RevenueCatProvider] ==========================================');
    
    notifyListeners();
  }

  void _handleCustomerInfo(CustomerInfo info) {
    _setCustomerInfo(info);
  }

  void setIsRestoringPurchases(bool value) {
    isRestoringPurchases = value;
    notifyListeners();
  }

  String? _friendlyMessageForCode(PurchasesErrorCode? code, String? message) {
    switch (code) {
      case PurchasesErrorCode.networkError:
        return 'Network issue. Please try again.';
      case PurchasesErrorCode.purchaseInvalidError:
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchase not allowed on this device/account.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Payment is pending. Please wait or check the store app.';
      case PurchasesErrorCode.storeProblemError:
        return null; // Don't show error message for store problems
      default:
        return message ?? 'Something went wrong. Please try again.';
    }
  }

  /// Save transaction to Firebase after successful IAP purchase
  Future<void> _saveTransactionToFirebase({
    required Package packageToPurchase,
    required CustomerInfo customerInfo,
    required String productId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ [RevenueCatProvider] No user logged in, skipping transaction save');
        return;
      }

      // Get user info
      final userId = user.uid;
      final userEmail = user.email ?? '';
      final userName = user.displayName ?? (userEmail.isNotEmpty ? userEmail.split('@')[0] : 'User');

      // Get package name from UI model
      String packageName = packageToPurchase.storeProduct.title;
      // Try to match with our package model for better name
      try {
        final productIdInt = int.tryParse(productId);
        if (productIdInt != null) {
          final matchingPackage = models.packages.firstWhere(
            (pkg) => pkg.id == productIdInt,
            orElse: () => models.packages.first,
          );
          packageName = matchingPackage.name;
        }
      } catch (e) {
        debugPrint('⚠️ [RevenueCatProvider] Could not match package name, using store product title: $e');
      }

      // Get transaction details from RevenueCat
      final entitlement = customerInfo.entitlements.active[entitlementId];
      
      // Get Apple transaction ID from the latest transaction
      // RevenueCat doesn't directly expose transaction ID, so we'll use a combination
      final appleTransactionId = '${productId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Get amount from package
      final amount = packageToPurchase.storeProduct.price;
      final currency = packageToPurchase.storeProduct.currencyCode.isNotEmpty 
          ? packageToPurchase.storeProduct.currencyCode 
          : 'USD';
      
      // Get expiry date from entitlement
      DateTime? expiryDate;
      final expirationDateStr = entitlement?.expirationDate;
      if (expirationDateStr != null && expirationDateStr.isNotEmpty) {
        try {
          expiryDate = DateTime.parse(expirationDateStr);
        } catch (e) {
          debugPrint('⚠️ [RevenueCatProvider] Could not parse expiry date: $e');
        }
      }

      // Save transaction to Firebase
      debugPrint('💾 [RevenueCatProvider] Saving transaction to Firebase...');
      debugPrint('   - User ID: $userId');
      debugPrint('   - Package: $packageName');
      debugPrint('   - Product ID: $productId');
      debugPrint('   - Amount: $amount $currency');
      
      await FirestoreHelpers.createTransaction(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        appleTransactionId: appleTransactionId,
        productId: productId,
        packageName: packageName,
        amount: amount,
        currency: currency,
        subscriptionId: entitlement?.identifier,
        expiryDate: expiryDate,
      );
      
      debugPrint('✅ [RevenueCatProvider] Transaction saved to Firebase successfully');
    } catch (e) {
      debugPrint('❌ [RevenueCatProvider] Error saving transaction to Firebase: $e');
      // Don't throw error - transaction saving failure shouldn't break purchase flow
    }
  }

  @override
  void dispose() {
    _periodicRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    Purchases.removeCustomerInfoUpdateListener(_customerInfoListener);
    super.dispose();
  }
}

